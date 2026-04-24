# MIT License
#
# Copyright (c) [2025] [Ashwin Natarajan]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""MCP Server implementation for exposing F1 telemetry data to AI tools."""

import asyncio
import json
import logging
from typing import Any, Dict, List, Optional
from datetime import datetime

from apps.backend.state_mgmt_layer import SessionState
from apps.backend.state_mgmt_layer.intf import (
    DriverInfoRsp,
    PeriodicUpdateData,
    RaceInfoData,
    StreamOverlayData,
)
from lib.mcp_server.constants import MCP_HTTP_PATH


class MCPServer:
    """
    Model Context Protocol server for F1 telemetry data.

    Provides AI tools (ChatGPT, Claude, Cursor, etc.) access to live
    F1 telemetry data through the MCP protocol using Server-Sent Events.
    """

    def __init__(self, session_state: SessionState, logger: logging.Logger):
        """
        Initialize the MCP server.

        Args:
            session_state: The session state containing telemetry data
            logger: Logger instance for debugging
        """
        self.session_state = session_state
        self.logger = logger
        self.tools = self._define_tools()

    def _define_tools(self) -> List[Dict[str, Any]]:
        """
        Define the available MCP tools that AI can invoke.

        Returns:
            List of tool definitions in MCP format
        """
        return [
            {
                "name": "get_race_info",
                "description": "Get current race status, session information, and overall race statistics including lap count, safety car status, weather conditions, and track temperatures.",
                "inputSchema": {"type": "object", "properties": {}, "required": []},
            },
            {
                "name": "get_telemetry_data",
                "description": "Get live telemetry data for all drivers including positions, lap times, tyre data, fuel levels, and performance metrics.",
                "inputSchema": {"type": "object", "properties": {}, "required": []},
            },
            {
                "name": "get_driver_info",
                "description": "Get detailed information about a specific driver including lap history, tyre wear, damage, ERS data, and stint information.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_index": {
                            "type": "integer",
                            "description": "The index of the driver (0-21)",
                            "minimum": 0,
                            "maximum": 21,
                        }
                    },
                    "required": ["driver_index"],
                },
            },
            {
                "name": "get_stream_overlay_data",
                "description": "Get stream overlay data optimized for broadcasting, including player position, delta times, and key race information.",
                "inputSchema": {"type": "object", "properties": {}, "required": []},
            },
            {
                "name": "analyze_tyre_strategy",
                "description": "Analyze tyre strategy by comparing multiple drivers' tyre wear, compound choices, and stint lengths.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_indices": {
                            "type": "array",
                            "items": {"type": "integer", "minimum": 0, "maximum": 21},
                            "description": "List of driver indices to compare (0-21)",
                        }
                    },
                    "required": [],
                },
            },
            {
                "name": "get_lap_comparison",
                "description": "Compare lap times between multiple drivers to analyze performance differences.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_indices": {
                            "type": "array",
                            "items": {"type": "integer", "minimum": 0, "maximum": 21},
                            "description": "List of driver indices to compare (0-21)",
                        },
                        "lap_number": {
                            "type": "integer",
                            "description": "Specific lap number to analyze (optional)",
                            "minimum": 1,
                        },
                    },
                    "required": [],
                },
            },
            {
                "name": "analyze_lap_time_consistency",
                "description": "Analyze a driver's lap time consistency, identify anomalies, calculate standard deviation, and track performance trends over recent laps.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_index": {
                            "type": "integer",
                            "description": "The index of the driver (0-21)",
                            "minimum": 0,
                            "maximum": 21,
                        },
                        "lap_count": {
                            "type": "integer",
                            "description": "Number of recent laps to analyze (default: 10)",
                            "minimum": 1,
                            "maximum": 100,
                        },
                    },
                    "required": ["driver_index"],
                },
            },
            {
                "name": "diagnose_performance_issues",
                "description": "Analyze telemetry to diagnose performance issues like tyre degradation, fuel impact, damage effects, and setup imbalances. Returns data-driven insights.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_index": {
                            "type": "integer",
                            "description": "The index of the driver (0-21)",
                            "minimum": 0,
                            "maximum": 21,
                        }
                    },
                    "required": ["driver_index"],
                },
            },
            {
                "name": "compare_to_leader",
                "description": "Compare driver's performance to P1 across pace, consistency, tyre management, and sector times with specific time deltas.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_index": {
                            "type": "integer",
                            "description": "The index of the driver (0-21)",
                            "minimum": 0,
                            "maximum": 21,
                        }
                    },
                    "required": ["driver_index"],
                },
            },
            {
                "name": "analyze_sector_performance",
                "description": "Deep sector analysis showing time loss/gain per sector with specific corner phase recommendations.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "driver_index": {
                            "type": "integer",
                            "description": "The index of the driver (0-21)",
                            "minimum": 0,
                            "maximum": 21,
                        },
                        "comparison_driver_index": {
                            "type": "integer",
                            "description": "Driver index to compare against (default: P1)",
                            "minimum": 0,
                            "maximum": 21,
                        },
                    },
                    "required": ["driver_index"],
                },
            },
        ]

    async def handle_request(
        self, method: str, params: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Handle an incoming MCP request.

        Args:
            method: The method/tool being called
            params: Parameters for the method call

        Returns:
            Response dictionary with results or error
        """
        try:
            if method == "tools/list":
                return {"tools": self.tools}
            elif method == "tools/call":
                tool_name = params.get("name") if params else None
                arguments = params.get("arguments", {}) if params else {}
                return await self._execute_tool(tool_name, arguments)
            else:
                return {
                    "error": {"code": -32601, "message": f"Method not found: {method}"}
                }
        except Exception as e:
            self.logger.error(f"Error handling MCP request: {e}", exc_info=True)
            return {"error": {"code": -32603, "message": f"Internal error: {str(e)}"}}

    async def _execute_tool(
        self, tool_name: str, arguments: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Execute a specific tool with given arguments.

        Args:
            tool_name: Name of the tool to execute
            arguments: Arguments for the tool

        Returns:
            Tool execution results
        """
        if tool_name == "get_race_info":
            data = RaceInfoData(self.session_state).toDict()
            return {"content": [{"type": "text", "text": json.dumps(data, indent=2)}]}

        elif tool_name == "get_telemetry_data":
            data = PeriodicUpdateData(self.session_state).toDict()
            return {"content": [{"type": "text", "text": json.dumps(data, indent=2)}]}

        elif tool_name == "get_driver_info":
            driver_index = arguments.get("driver_index")
            if driver_index is None:
                return {
                    "error": {
                        "code": -32602,
                        "message": "Missing driver_index parameter",
                    }
                }

            try:
                data = DriverInfoRsp(self.session_state, int(driver_index)).toDict()
                return {
                    "content": [{"type": "text", "text": json.dumps(data, indent=2)}]
                }
            except (ValueError, IndexError) as e:
                return {
                    "error": {
                        "code": -32602,
                        "message": f"Invalid driver_index: {str(e)}",
                    }
                }

        elif tool_name == "get_stream_overlay_data":
            data = StreamOverlayData(self.session_state).toDict(show_sample_data=False)
            return {"content": [{"type": "text", "text": json.dumps(data, indent=2)}]}

        elif tool_name == "analyze_tyre_strategy":
            driver_indices = arguments.get("driver_indices", [])
            if not driver_indices:
                data = PeriodicUpdateData(self.session_state).toDict()
                driver_indices = list(range(len(data.get("drivers", []))))

            analysis = self._analyze_tyres(driver_indices)
            return {
                "content": [{"type": "text", "text": json.dumps(analysis, indent=2)}]
            }

        elif tool_name == "get_lap_comparison":
            driver_indices = arguments.get("driver_indices", [])
            lap_number = arguments.get("lap_number")

            comparison = self._compare_laps(driver_indices, lap_number)
            return {
                "content": [{"type": "text", "text": json.dumps(comparison, indent=2)}]
            }

        elif tool_name == "analyze_lap_time_consistency":
            driver_index = arguments.get("driver_index")
            lap_count = arguments.get("lap_count", 10)

            if driver_index is None:
                return {
                    "error": {
                        "code": -32602,
                        "message": "Missing driver_index parameter",
                    }
                }

            analysis = self._analyze_consistency(int(driver_index), lap_count)
            return {
                "content": [{"type": "text", "text": json.dumps(analysis, indent=2)}]
            }

        elif tool_name == "diagnose_performance_issues":
            driver_index = arguments.get("driver_index")

            if driver_index is None:
                return {
                    "error": {
                        "code": -32602,
                        "message": "Missing driver_index parameter",
                    }
                }

            diagnosis = self._diagnose_issues(int(driver_index))
            return {
                "content": [{"type": "text", "text": json.dumps(diagnosis, indent=2)}]
            }

        elif tool_name == "compare_to_leader":
            driver_index = arguments.get("driver_index")

            if driver_index is None:
                return {
                    "error": {
                        "code": -32602,
                        "message": "Missing driver_index parameter",
                    }
                }

            comparison = self._compare_to_p1(int(driver_index))
            return {
                "content": [{"type": "text", "text": json.dumps(comparison, indent=2)}]
            }

        elif tool_name == "analyze_sector_performance":
            driver_index = arguments.get("driver_index")
            comparison_driver = arguments.get("comparison_driver_index")

            if driver_index is None:
                return {
                    "error": {
                        "code": -32602,
                        "message": "Missing driver_index parameter",
                    }
                }

            analysis = self._analyze_sectors(int(driver_index), comparison_driver)
            return {
                "content": [{"type": "text", "text": json.dumps(analysis, indent=2)}]
            }

        else:
            return {"error": {"code": -32601, "message": f"Unknown tool: {tool_name}"}}

    def _analyze_tyres(self, driver_indices: List[int]) -> Dict[str, Any]:
        """Analyze tyre strategy for specified drivers."""
        analysis = {"timestamp": datetime.now().isoformat(), "drivers": []}

        for idx in driver_indices:
            try:
                driver_data = DriverInfoRsp(self.session_state, idx).toDict()
                analysis["drivers"].append(
                    {
                        "driver_index": idx,
                        "name": driver_data.get("name", "Unknown"),
                        "current_tyre": driver_data.get("tyre_data", {}).get(
                            "current_compound"
                        ),
                        "tyre_age": driver_data.get("tyre_data", {}).get("age_laps"),
                        "tyre_wear": driver_data.get("tyre_data", {}).get("wear"),
                        "stint_history": driver_data.get("tyre_stint_history", []),
                    }
                )
            except Exception as e:
                self.logger.error(f"Error analyzing driver {idx}: {e}")

        return analysis

    def _compare_laps(
        self, driver_indices: List[int], lap_number: Optional[int] = None
    ) -> Dict[str, Any]:
        """Compare lap times between drivers."""
        comparison = {
            "timestamp": datetime.now().isoformat(),
            "lap_number": lap_number,
            "drivers": [],
        }

        for idx in driver_indices:
            try:
                driver_data = DriverInfoRsp(self.session_state, idx).toDict()
                lap_history = driver_data.get("lap_time_history", [])

                driver_comparison = {
                    "driver_index": idx,
                    "name": driver_data.get("name", "Unknown"),
                    "best_lap": driver_data.get("best_lap_time_ms"),
                    "last_lap": driver_data.get("last_lap_time_ms"),
                }

                if lap_number and lap_history:
                    for lap in lap_history:
                        if lap.get("lap_number") == lap_number:
                            driver_comparison["specific_lap"] = lap
                            break

                comparison["drivers"].append(driver_comparison)
            except Exception as e:
                self.logger.error(f"Error comparing laps for driver {idx}: {e}")

        return comparison

    def _analyze_consistency(self, driver_index: int, lap_count: int) -> Dict[str, Any]:
        """Analyze lap time consistency for a driver."""
        try:
            driver_data = DriverInfoRsp(self.session_state, driver_index).toDict()
            lap_history = driver_data.get("lap_time_history", [])

            if not lap_history:
                return {"error": "No lap history available"}

            # Get last N laps
            recent_laps = (
                lap_history[-lap_count:]
                if len(lap_history) > lap_count
                else lap_history
            )
            lap_times = [
                lap.get("lap_time_ms", 0)
                for lap in recent_laps
                if lap.get("lap_time_ms", 0) > 0
            ]

            if len(lap_times) < 2:
                return {"error": "Insufficient lap data for analysis"}

            # Calculate statistics
            import statistics

            mean_time = statistics.mean(lap_times)
            std_dev = statistics.stdev(lap_times) if len(lap_times) > 1 else 0
            best_time = min(lap_times)
            worst_time = max(lap_times)

            # Identify trend (improving or degrading)
            if len(lap_times) >= 5:
                first_half = lap_times[: len(lap_times) // 2]
                second_half = lap_times[len(lap_times) // 2 :]
                trend = (
                    "improving"
                    if statistics.mean(second_half) < statistics.mean(first_half)
                    else "degrading"
                )
            else:
                trend = "insufficient_data"

            # Calculate consistency score (lower is better)
            consistency_score = (std_dev / mean_time) * 100 if mean_time > 0 else 0

            return {
                "driver_index": driver_index,
                "driver_name": driver_data.get("name", "Unknown"),
                "laps_analyzed": len(lap_times),
                "mean_lap_time_ms": round(mean_time, 0),
                "std_deviation_ms": round(std_dev, 0),
                "consistency_score_percent": round(consistency_score, 2),
                "best_lap_ms": best_time,
                "worst_lap_ms": worst_time,
                "delta_best_to_worst_ms": worst_time - best_time,
                "performance_trend": trend,
                "lap_times": lap_times,
                "interpretation": self._interpret_consistency(
                    consistency_score, trend, std_dev
                ),
            }
        except Exception as e:
            self.logger.error(f"Error analyzing consistency: {e}")
            return {"error": str(e)}

    def _interpret_consistency(self, score: float, trend: str, std_dev: float) -> str:
        """Interpret consistency metrics."""
        if score < 0.5:
            consistency = "Excellent - Very consistent lap times"
        elif score < 1.0:
            consistency = "Good - Reasonably consistent"
        elif score < 1.5:
            consistency = "Fair - Some inconsistency present"
        else:
            consistency = "Poor - High lap time variation"

        if trend == "improving":
            trend_msg = "Lap times are improving (getting faster)"
        elif trend == "degrading":
            trend_msg = "Lap times are degrading (getting slower)"
        else:
            trend_msg = "Trend unclear - need more laps"

        if std_dev > 500:
            issue = "Large variation suggests setup or driving inconsistency issues"
        elif std_dev > 300:
            issue = "Moderate variation - focus on consistency"
        else:
            issue = "Good pace stability"

        return f"{consistency}. {trend_msg}. {issue}"

    def _diagnose_issues(self, driver_index: int) -> Dict[str, Any]:
        """Diagnose performance issues from telemetry data."""
        try:
            driver_data = DriverInfoRsp(self.session_state, driver_index).toDict()
            lap_history = driver_data.get("lap_time_history", [])
            tyre_data = driver_data.get("tyre_data", {})

            issues = []
            recommendations = []

            # Analyze tyre degradation
            if lap_history and len(lap_history) >= 5:
                recent_5 = [
                    lap.get("lap_time_ms", 0)
                    for lap in lap_history[-5:]
                    if lap.get("lap_time_ms", 0) > 0
                ]
                if len(recent_5) >= 5:
                    deg_rate = (recent_5[-1] - recent_5[0]) / len(recent_5)
                    if deg_rate > 100:  # Losing > 100ms per lap
                        issues.append(
                            {
                                "type": "tyre_degradation",
                                "severity": "high",
                                "description": f"Significant pace loss: {round(deg_rate)}ms per lap over last 5 laps",
                                "data": {
                                    "degradation_rate_ms_per_lap": round(deg_rate, 1)
                                },
                            }
                        )
                        recommendations.append(
                            "Consider pitting soon - tyre performance dropping rapidly"
                        )
                        recommendations.append(
                            "If staying out, reduce tyre stress: higher pressures, less aggressive inputs"
                        )

            # Check tyre wear
            tyre_wear = tyre_data.get("wear", {})
            if isinstance(tyre_wear, dict):
                avg_wear = sum(tyre_wear.values()) / len(tyre_wear) if tyre_wear else 0
                if avg_wear > 50:
                    issues.append(
                        {
                            "type": "high_tyre_wear",
                            "severity": "medium",
                            "description": f"Average tyre wear at {round(avg_wear, 1)}%",
                            "data": tyre_wear,
                        }
                    )
                    recommendations.append("High tyre wear - plan pit stop soon")

            # Check damage
            damage = driver_data.get("damage", {})
            if isinstance(damage, dict):
                total_damage = sum(damage.values()) if damage else 0
                if total_damage > 10:
                    issues.append(
                        {
                            "type": "car_damage",
                            "severity": "high",
                            "description": f"Car damage detected: {round(total_damage, 1)}%",
                            "data": damage,
                        }
                    )
                    recommendations.append(
                        "Car damage affecting performance - consider repairs at next pit stop"
                    )

            # Analyze lap time consistency
            if lap_history and len(lap_history) >= 5:
                lap_times = [
                    lap.get("lap_time_ms", 0)
                    for lap in lap_history[-10:]
                    if lap.get("lap_time_ms", 0) > 0
                ]
                if len(lap_times) >= 5:
                    import statistics

                    std_dev = statistics.stdev(lap_times)
                    if std_dev > 500:
                        issues.append(
                            {
                                "type": "inconsistent_pace",
                                "severity": "medium",
                                "description": f"High lap time variation: {round(std_dev)}ms standard deviation",
                                "data": {"std_deviation_ms": round(std_dev, 1)},
                            }
                        )
                        recommendations.append(
                            "Focus on consistent driving - large lap time variations detected"
                        )
                        recommendations.append(
                            "Possible causes: setup imbalance, tyre temperature management, or driving style"
                        )

            if not issues:
                issues.append(
                    {
                        "type": "no_issues",
                        "severity": "none",
                        "description": "No significant performance issues detected",
                        "data": {},
                    }
                )
                recommendations.append(
                    "Performance looks stable - maintain current pace and strategy"
                )

            return {
                "driver_index": driver_index,
                "driver_name": driver_data.get("name", "Unknown"),
                "timestamp": datetime.now().isoformat(),
                "issues_found": len([i for i in issues if i["type"] != "no_issues"]),
                "issues": issues,
                "recommendations": recommendations,
                "current_tyre_age": tyre_data.get("age_laps", 0),
                "current_position": driver_data.get("position", 0),
            }
        except Exception as e:
            self.logger.error(f"Error diagnosing issues: {e}")
            return {"error": str(e)}

    def _compare_to_p1(self, driver_index: int) -> Dict[str, Any]:
        """Compare driver performance to race leader."""
        try:
            telemetry = PeriodicUpdateData(self.session_state).toDict()
            drivers = telemetry.get("drivers", [])

            # Find P1
            p1_driver = None
            for driver in drivers:
                if driver.get("position") == 1:
                    p1_driver = driver
                    break

            if not p1_driver:
                return {"error": "Could not find race leader"}

            # Get detailed data for both drivers
            driver_data = DriverInfoRsp(self.session_state, driver_index).toDict()
            p1_index = p1_driver.get("driver_index", 0)
            p1_data = (
                DriverInfoRsp(self.session_state, p1_index).toDict()
                if p1_index != driver_index
                else driver_data
            )

            # Compare best laps
            driver_best = driver_data.get("best_lap_time_ms", 0)
            p1_best = p1_data.get("best_lap_time_ms", 0)
            pace_delta = (
                driver_best - p1_best if driver_best > 0 and p1_best > 0 else None
            )

            # Compare last laps
            driver_last = driver_data.get("last_lap_time_ms", 0)
            p1_last = p1_data.get("last_lap_time_ms", 0)
            last_lap_delta = (
                driver_last - p1_last if driver_last > 0 and p1_last > 0 else None
            )

            # Compare tyre strategies
            driver_tyre = driver_data.get("tyre_data", {})
            p1_tyre = p1_data.get("tyre_data", {})

            return {
                "driver_index": driver_index,
                "driver_name": driver_data.get("name", "Unknown"),
                "p1_index": p1_index,
                "p1_name": p1_data.get("name", "Unknown"),
                "position_gap": driver_data.get("position", 0) - 1,
                "pace_comparison": {
                    "driver_best_lap_ms": driver_best,
                    "p1_best_lap_ms": p1_best,
                    "delta_to_p1_best_ms": pace_delta,
                    "delta_description": (
                        self._format_delta(pace_delta) if pace_delta else "N/A"
                    ),
                },
                "current_pace": {
                    "driver_last_lap_ms": driver_last,
                    "p1_last_lap_ms": p1_last,
                    "delta_to_p1_last_ms": last_lap_delta,
                    "delta_description": (
                        self._format_delta(last_lap_delta) if last_lap_delta else "N/A"
                    ),
                },
                "tyre_comparison": {
                    "driver_compound": driver_tyre.get("current_compound", "Unknown"),
                    "driver_age": driver_tyre.get("age_laps", 0),
                    "p1_compound": p1_tyre.get("current_compound", "Unknown"),
                    "p1_age": p1_tyre.get("age_laps", 0),
                },
                "analysis": self._analyze_p1_gap(
                    pace_delta, last_lap_delta, driver_tyre, p1_tyre
                ),
            }
        except Exception as e:
            self.logger.error(f"Error comparing to P1: {e}")
            return {"error": str(e)}

    def _format_delta(self, delta_ms: float) -> str:
        """Format time delta in human-readable format."""
        if delta_ms is None:
            return "N/A"
        sign = "+" if delta_ms > 0 else ""
        seconds = abs(delta_ms) / 1000
        return f"{sign}{seconds:.3f}s"

    def _analyze_p1_gap(self, pace_delta, last_lap_delta, driver_tyre, p1_tyre) -> str:
        """Analyze gap to P1 and provide insights."""
        if pace_delta is None:
            return "Insufficient data for comparison"

        if pace_delta < 100:
            pace_msg = "Very close on ultimate pace - competitive for wins"
        elif pace_delta < 300:
            pace_msg = "Decent pace but losing ~0.3s per lap on pure speed"
        elif pace_delta < 500:
            pace_msg = "Significant pace deficit - setup optimization needed"
        else:
            pace_msg = "Large pace gap - major setup or driving improvements required"

        if last_lap_delta and abs(last_lap_delta) < abs(pace_delta):
            trend = "Currently matching P1's pace despite slower best lap"
        elif last_lap_delta and last_lap_delta > pace_delta + 200:
            trend = "Pace degrading relative to P1 - possible tyre/fuel issue"
        else:
            trend = "Pace consistent with best lap delta"

        tyre_msg = ""
        if driver_tyre.get("age_laps", 0) > p1_tyre.get("age_laps", 0) + 3:
            tyre_msg = "Older tyres than P1 - consider pit strategy"

        return f"{pace_msg}. {trend}. {tyre_msg}".strip()

    def _analyze_sectors(
        self, driver_index: int, comparison_driver_index: Optional[int] = None
    ) -> Dict[str, Any]:
        """Analyze sector performance in detail."""
        try:
            driver_data = DriverInfoRsp(self.session_state, driver_index).toDict()

            # If no comparison driver specified, use P1
            if comparison_driver_index is None:
                telemetry = PeriodicUpdateData(self.session_state).toDict()
                for driver in telemetry.get("drivers", []):
                    if driver.get("position") == 1:
                        comparison_driver_index = driver.get("driver_index", 0)
                        break

            if comparison_driver_index is None:
                return {"error": "Could not find comparison driver"}

            comp_data = DriverInfoRsp(
                self.session_state, comparison_driver_index
            ).toDict()

            # Get lap histories
            driver_laps = driver_data.get("lap_time_history", [])
            comp_laps = comp_data.get("lap_time_history", [])

            if not driver_laps or not comp_laps:
                return {"error": "Insufficient lap data for sector analysis"}

            # Get most recent laps with sector data
            driver_recent = driver_laps[-1] if driver_laps else {}
            comp_recent = comp_laps[-1] if comp_laps else {}

            driver_sectors = driver_recent.get("sector_times_ms", {})
            comp_sectors = comp_recent.get("sector_times_ms", {})

            sector_analysis = []
            total_time_loss = 0

            for sector_num in range(1, 4):  # Sectors 1, 2, 3
                sector_key = f"sector_{sector_num}"
                driver_time = driver_sectors.get(sector_key, 0)
                comp_time = comp_sectors.get(sector_key, 0)

                if driver_time > 0 and comp_time > 0:
                    delta = driver_time - comp_time
                    total_time_loss += delta

                    sector_analysis.append(
                        {
                            "sector": sector_num,
                            "driver_time_ms": driver_time,
                            "comparison_time_ms": comp_time,
                            "delta_ms": delta,
                            "delta_description": self._format_delta(delta),
                            "percentage_of_total_loss": 0,  # Will calculate after
                        }
                    )

            # Calculate percentages
            for sector in sector_analysis:
                if total_time_loss != 0:
                    sector["percentage_of_total_loss"] = round(
                        (sector["delta_ms"] / total_time_loss) * 100, 1
                    )

            # Find biggest time loss sector
            worst_sector = (
                max(sector_analysis, key=lambda x: x["delta_ms"])
                if sector_analysis
                else None
            )

            return {
                "driver_index": driver_index,
                "driver_name": driver_data.get("name", "Unknown"),
                "comparison_driver_index": comparison_driver_index,
                "comparison_driver_name": comp_data.get("name", "Unknown"),
                "sector_breakdown": sector_analysis,
                "total_time_loss_ms": round(total_time_loss, 1),
                "total_time_loss_description": self._format_delta(total_time_loss),
                "biggest_loss_sector": worst_sector["sector"] if worst_sector else None,
                "focus_area": (
                    self._recommend_focus_area(worst_sector)
                    if worst_sector
                    else "Insufficient data"
                ),
            }
        except Exception as e:
            self.logger.error(f"Error analyzing sectors: {e}")
            return {"error": str(e)}

    def _recommend_focus_area(self, worst_sector: Dict[str, Any]) -> str:
        """Recommend what to focus on based on sector analysis."""
        sector_num = worst_sector["sector"]
        delta = worst_sector["delta_ms"]

        if delta < 50:
            return f"Sector {sector_num} is competitive - maintain current approach"
        elif delta < 150:
            return f"Sector {sector_num}: Minor improvements needed - focus on corner exit speed and line optimization"
        elif delta < 300:
            return f"Sector {sector_num}: Significant time loss - review racing line, braking points, and gear selection"
        else:
            return f"Sector {sector_num}: Major deficit - consider setup changes (aero balance, diff, brake bias) for these corner types"

    async def stream_events(self):
        """
        Generate Server-Sent Events for MCP protocol.

        Yields SSE-formatted messages for the MCP client.
        """
        yield f"event: endpoint\ndata: {MCP_HTTP_PATH}\n\n"

        tools_response = await self.handle_request("tools/list")
        yield f"event: message\ndata: {json.dumps(tools_response)}\n\n"

        while True:
            await asyncio.sleep(30)
            yield f"event: ping\ndata: {json.dumps({'timestamp': datetime.now().isoformat()})}\n\n"
