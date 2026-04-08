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

        def _periodic_table_entries() -> List[Dict[str, Any]]:
            periodic = PeriodicUpdateData(self.session_state).toJSON()
            entries = periodic.get("table-entries")
            return entries if isinstance(entries, list) else []

        def _all_driver_indices_from_periodic() -> List[int]:
            indices: List[int] = []
            for row in _periodic_table_entries():
                idx = row.get("driver-info", {}).get("index")
                if isinstance(idx, int):
                    indices.append(idx)
            return indices

        if tool_name == "get_race_info":
            data = RaceInfoData(self.session_state).toJSON()
            return {"content": [{"type": "text", "text": json.dumps(data, indent=2)}]}

        elif tool_name == "get_telemetry_data":
            data = PeriodicUpdateData(self.session_state).toJSON()
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
                data = DriverInfoRsp(self.session_state, int(driver_index)).toJSON()
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
            data = StreamOverlayData(self.session_state).toJSON(
                stream_overlay_start_sample_data=False
            )
            return {"content": [{"type": "text", "text": json.dumps(data, indent=2)}]}

        elif tool_name == "analyze_tyre_strategy":
            driver_indices = arguments.get("driver_indices", [])
            if not driver_indices:
                driver_indices = _all_driver_indices_from_periodic()

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
                driver_data = DriverInfoRsp(self.session_state, idx).toJSON()
                analysis["drivers"].append(
                    {
                        "driver_index": idx,
                        "name": driver_data.get("driver-name", "Unknown"),
                        "current_tyre": driver_data.get("tyre-info", {}).get(
                            "visual-tyre-compound"
                        ),
                        "tyre_age": driver_data.get("tyre-info", {}).get("tyre-age"),
                        "tyre_wear": driver_data.get("tyre-info", {}).get(
                            "current-wear"
                        ),
                        "stint_history": driver_data.get("tyre-stint-history", []),
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
                driver_data = DriverInfoRsp(self.session_state, idx).toJSON()
                lap_history = driver_data.get("lap-time-history-data", [])

                driver_comparison = {
                    "driver_index": idx,
                    "name": driver_data.get("driver-name", "Unknown"),
                    "best_lap": driver_data.get("best-lap-time-in-ms"),
                    "last_lap": driver_data.get("last-lap-time-in-ms"),
                }

                if lap_number and lap_history:
                    for lap in lap_history:
                        if lap.get("lap-number") == lap_number:
                            driver_comparison["specific_lap"] = lap
                            break

                comparison["drivers"].append(driver_comparison)
            except Exception as e:
                self.logger.error(f"Error comparing laps for driver {idx}: {e}")

        return comparison

    def _analyze_consistency(self, driver_index: int, lap_count: int) -> Dict[str, Any]:
        """Analyze lap time consistency for a driver."""
        try:
            driver_data = DriverInfoRsp(self.session_state, driver_index).toJSON()
            lap_history = driver_data.get("lap-time-history-data", [])

            if not lap_history:
                return {"error": "No lap history available"}

            # Get last N laps
            recent_laps = (
                lap_history[-lap_count:]
                if len(lap_history) > lap_count
                else lap_history
            )
            lap_times = [
                lap.get("lap-time-in-ms", 0)
                for lap in recent_laps
                if lap.get("lap-time-in-ms", 0) > 0
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
                "driver_name": driver_data.get("driver-name", "Unknown"),
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
            driver_data = DriverInfoRsp(self.session_state, driver_index).toJSON()
            lap_history = driver_data.get("lap-time-history-data", [])
            tyre_data = driver_data.get("tyre-info", {})

            issues = []
            recommendations = []

            # Analyze tyre degradation
            if lap_history and len(lap_history) >= 5:
                recent_5 = [
                    lap.get("lap-time-in-ms", 0)
                    for lap in lap_history[-5:]
                    if lap.get("lap-time-in-ms", 0) > 0
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
            tyre_wear = tyre_data.get("current-wear", {})
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
                    lap.get("lap-time-in-ms", 0)
                    for lap in lap_history[-10:]
                    if lap.get("lap-time-in-ms", 0) > 0
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
                "driver_name": driver_data.get("driver-name", "Unknown"),
                "timestamp": datetime.now().isoformat(),
                "issues_found": len([i for i in issues if i["type"] != "no_issues"]),
                "issues": issues,
                "recommendations": recommendations,
                "current_tyre_age": tyre_data.get("tyre-age", 0),
                "current_position": driver_data.get("position", 0),
            }
        except Exception as e:
            self.logger.error(f"Error diagnosing issues: {e}")
            return {"error": str(e)}

    def _compare_to_p1(self, driver_index: int) -> Dict[str, Any]:
        """Compare driver performance to race leader."""
        try:
            periodic = PeriodicUpdateData(self.session_state).toJSON()
            drivers = periodic.get("table-entries", [])

            # Find P1
            p1_driver = None
            for driver in drivers:
                if driver.get("driver-info", {}).get("position") == 1:
                    p1_driver = driver
                    break

            if not p1_driver:
                return {"error": "Could not find race leader"}

            # Get detailed data for both drivers
            driver_data = DriverInfoRsp(self.session_state, driver_index).toJSON()
            p1_index = p1_driver.get("driver-info", {}).get("index", 0)
            p1_data = (
                DriverInfoRsp(self.session_state, p1_index).toJSON()
                if p1_index != driver_index
                else driver_data
            )

            # Compare best laps
            driver_best = driver_data.get("best-lap-time-in-ms", 0)
            p1_best = p1_data.get("best-lap-time-in-ms", 0)
            pace_delta = (
                driver_best - p1_best if driver_best > 0 and p1_best > 0 else None
            )

            # Compare last laps
            driver_last = driver_data.get("last-lap-time-in-ms", 0)
            p1_last = p1_data.get("last-lap-time-in-ms", 0)
            last_lap_delta = (
                driver_last - p1_last if driver_last > 0 and p1_last > 0 else None
            )

            # Compare tyre strategies
            driver_tyre = driver_data.get("tyre-info", {})
            p1_tyre = p1_data.get("tyre-info", {})

            return {
                "driver_index": driver_index,
                "driver_name": driver_data.get("driver-name", "Unknown"),
                "p1_index": p1_index,
                "p1_name": p1_data.get("driver-name", "Unknown"),
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
                    "driver_compound": driver_tyre.get(
                        "visual-tyre-compound", "Unknown"
                    ),
                    "driver_age": driver_tyre.get("tyre-age", 0),
                    "p1_compound": p1_tyre.get("visual-tyre-compound", "Unknown"),
                    "p1_age": p1_tyre.get("tyre-age", 0),
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
            driver_data = DriverInfoRsp(self.session_state, driver_index).toJSON()

            # If no comparison driver specified, use P1
            if comparison_driver_index is None:
                periodic = PeriodicUpdateData(self.session_state).toJSON()
                for driver in periodic.get("table-entries", []):
                    if driver.get("driver-info", {}).get("position") == 1:
                        comparison_driver_index = driver.get("driver-info", {}).get(
                            "index", 0
                        )
                        break

            if comparison_driver_index is None:
                return {"error": "Could not find comparison driver"}

            comp_data = DriverInfoRsp(
                self.session_state, comparison_driver_index
            ).toJSON()

            # Get lap histories
            driver_laps = driver_data.get("lap-time-history-data", [])
            comp_laps = comp_data.get("lap-time-history-data", [])

            if not driver_laps or not comp_laps:
                return {"error": "Insufficient lap data for sector analysis"}

            # Get most recent laps with sector data
            driver_recent = driver_laps[-1] if driver_laps else {}
            comp_recent = comp_laps[-1] if comp_laps else {}

            driver_sectors = {
                "sector_1": driver_recent.get("sector-1-time-in-ms", 0),
                "sector_2": driver_recent.get("sector-2-time-in-ms", 0),
                "sector_3": driver_recent.get("sector-3-time-in-ms", 0),
            }
            comp_sectors = {
                "sector_1": comp_recent.get("sector-1-time-in-ms", 0),
                "sector_2": comp_recent.get("sector-2-time-in-ms", 0),
                "sector_3": comp_recent.get("sector-3-time-in-ms", 0),
            }

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
                "driver_name": driver_data.get("driver-name", "Unknown"),
                "comparison_driver_index": comparison_driver_index,
                "comparison_driver_name": comp_data.get("driver-name", "Unknown"),
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
        yield "event: endpoint\ndata: /mcp\n\n"

        tools_response = await self.handle_request("tools/list")
        yield f"event: message\ndata: {json.dumps(tools_response)}\n\n"

        while True:
            await asyncio.sleep(30)
            yield f"event: ping\ndata: {json.dumps({'timestamp': datetime.now().isoformat()})}\n\n"

    async def handle_chat(
        self, message: str, telemetry: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Handle chat requests from the F1 Race Engineer interface.

        Args:
            message: User question/request
            telemetry: Optional telemetry data context

        Returns:
            Dict containing response, analysis, and recommendations
        """
        try:
            # Analyze telemetry if provided
            analysis = None
            if telemetry:
                analysis = self._analyze_telemetry(telemetry)

            # Generate intelligent response based on question
            response_text = await self._generate_race_engineer_response(
                message, telemetry, analysis
            )

            # Extract recommendations from analysis
            recommendations = []
            if analysis and "recommendations" in analysis:
                recommendations = analysis["recommendations"]

            return {
                "response": response_text,
                "analysis": analysis,
                "recommendations": recommendations,
            }

        except Exception as e:
            self.logger.error(f"Chat error: {e}")
            return {
                "response": f"I apologize, I encountered an error analyzing your request. Error: {str(e)}",
                "analysis": None,
                "recommendations": [],
            }

    def _analyze_telemetry(self, telemetry: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze telemetry data and identify issues."""
        analysis = {
            "timestamp": datetime.now().isoformat(),
            "issues": [],
            "recommendations": [],
        }

        periodic = telemetry.get("periodic") if isinstance(telemetry, dict) else None
        player_driver = (
            telemetry.get("playerDriver") if isinstance(telemetry, dict) else None
        )
        if isinstance(periodic, dict) and not player_driver:
            player_idx = telemetry.get("playerIndex")
            if isinstance(player_idx, int):
                player_driver = telemetry.get("playerDriver")

        # Analyze tyre temperatures
        if telemetry.get("tyre_temps"):
            temps = telemetry["tyre_temps"]
            if isinstance(temps, dict):
                temp_values = list(temps.values())
                avg_temp = sum(temp_values) / len(temp_values)
                temp_diff = max(temp_values) - min(temp_values)

                if temp_diff > 15:
                    analysis["issues"].append(
                        f"Tyre temperature imbalance: {temp_diff:.1f}°C difference"
                    )
                    if temps.get("FL", 0) > avg_temp + 10:
                        analysis["recommendations"].append(
                            "Front wing angle: Reduce by 1-2 clicks for better front-end balance"
                        )
                    elif temps.get("RL", 0) > avg_temp + 10:
                        analysis["recommendations"].append(
                            "Rear anti-roll bar: Increase stiffness by 1 click"
                        )

        # Analyze tyre wear
        if telemetry.get("tyre_wear"):
            wear = telemetry["tyre_wear"]
            if isinstance(wear, dict):
                wear_values = list(wear.values())
                max_wear = max(wear_values)
                if max_wear > 50:
                    analysis["issues"].append(
                        f"High tyre wear detected: {max_wear:.0f}%"
                    )
                    analysis["recommendations"].append(
                        "Consider pit stop within next 3-5 laps"
                    )

        # Analyze fuel
        if telemetry.get("fuel"):
            fuel = telemetry["fuel"]
            if isinstance(fuel, (int, float)) and fuel < 2.0:
                analysis["issues"].append(f"Low fuel: {fuel:.1f} laps remaining")
                analysis["recommendations"].append(
                    "Enable fuel-saving mode in Sector 3"
                )

        # Prefer rich periodic/player data if present (Strategy Center)
        if isinstance(periodic, dict):
            entries = periodic.get("table-entries")
            if isinstance(entries, list):
                player_row = next(
                    (
                        r
                        for r in entries
                        if r.get("driver-info", {}).get("is-player") is True
                    ),
                    None,
                )
            else:
                player_row = None

            if isinstance(player_row, dict):
                tyre_age = player_row.get("tyre-info", {}).get("tyre-age")
                tyre_life = player_row.get("tyre-info", {}).get("tyre-life-remaining")
                tyre_wear = player_row.get("tyre-info", {}).get("current-wear")
                if isinstance(tyre_age, (int, float)) and isinstance(
                    tyre_life, (int, float)
                ):
                    if tyre_life <= 2:
                        analysis["issues"].append(
                            f"Tyre life low: ~{tyre_life:.1f} laps remaining"
                        )
                        analysis["recommendations"].append(
                            "Pit soon if you need pace; manage temps to extend if staying out"
                        )
                if isinstance(tyre_wear, dict):
                    wear_values = [
                        v for v in tyre_wear.values() if isinstance(v, (int, float))
                    ]
                    if wear_values:
                        max_wear = max(wear_values)
                        if max_wear >= 65:
                            analysis["issues"].append(
                                f"High tyre wear: {max_wear:.0f}% (max corner)"
                            )
                            analysis["recommendations"].append(
                                "Avoid sliding and aggressive traction to stabilize wear"
                            )

        if not analysis["issues"] and isinstance(player_driver, dict):
            # Mild “nothing obvious” result to avoid canned prompt gating
            analysis["recommendations"].append(
                "Ask anything—I'll use your live telemetry context automatically."
            )

        return analysis

    async def _generate_race_engineer_response(
        self,
        message: str,
        telemetry: Optional[Dict[str, Any]],
        analysis: Optional[Dict[str, Any]],
    ) -> str:
        """Generate intelligent race engineer response."""
        message_lower = message.lower()

        # Context-aware responses
        if "understeer" in message_lower:
            return self._handle_understeer_query(telemetry, analysis)
        elif "oversteer" in message_lower:
            return self._handle_oversteer_query(telemetry, analysis)
        elif "tyre" in message_lower or "tire" in message_lower:
            return self._handle_tyre_query(telemetry, analysis)
        elif "fuel" in message_lower:
            return self._handle_fuel_query(telemetry, analysis)
        elif "setup" in message_lower or "balance" in message_lower:
            return self._handle_setup_query(telemetry, analysis)
        elif (
            "lap" in message_lower
            or "sector" in message_lower
            or "time" in message_lower
        ):
            return self._handle_laptime_query(telemetry, analysis)
        elif "pit" in message_lower or "strategy" in message_lower:
            return self._handle_strategy_query(telemetry, analysis)
        else:
            return self._handle_general_query(message, telemetry, analysis)

    def _handle_understeer_query(self, telemetry, analysis) -> str:
        return """🔧 UNDERSTEER DIAGNOSIS

**Recommended Changes:**
1. **Front Wing:** Increase angle by +1 click for more front-end grip
2. **Front ARB:** Reduce stiffness by -2 clicks for mechanical compliance
3. **Brake Bias:** Move forward to 56-57% for better front loading
4. **Off-Throttle Diff:** Reduce to 55% for improved turn-in rotation

**Expected Impact:**
Sharper turn-in response with reduced push in slow-medium corners. May slightly increase front tyre degradation.

**Validation:** Focus on corner entry feel and mid-corner stability on your next run."""

    def _handle_oversteer_query(self, telemetry, analysis) -> str:
        return """🔧 OVERSTEER DIAGNOSIS

**Recommended Changes:**
1. **Rear Wing:** Increase angle by +1-2 clicks for rear stability
2. **On-Throttle Diff:** Increase to 70-75% for better traction
3. **Rear ARB:** Reduce stiffness by -2 clicks
4. **Rear Suspension:** Increase stiffness by +1 for better mechanical grip

**Expected Impact:**
More planted rear end on corner exit, better traction out of slow corners. May cost 1-2 kph top speed.

**Validation:** Monitor rear tyre temperatures and corner exit confidence."""

    def _handle_tyre_query(self, telemetry, analysis) -> str:
        if analysis and analysis.get("issues"):
            response = "📊 **Tyre Analysis:**\n\n"
            for issue in analysis["issues"]:
                if "tyre" in issue.lower() or "tire" in issue.lower():
                    response += f"- {issue}\n"
            if analysis.get("recommendations"):
                response += "\n💡 **Actions:**\n"
                for rec in analysis["recommendations"]:
                    if (
                        "tyre" in rec.lower()
                        or "tire" in rec.lower()
                        or "pit" in rec.lower()
                    ):
                        response += f"- {rec}\n"
            return response
        return """🏁 **Tyre Management Strategy:**

Monitor tyre temps (optimal: 85-95°C) and wear rate. Typical pit windows:
- **Soft:** 8-12 laps
- **Medium:** 15-20 laps
- **Hard:** 25+ laps

Adjust pressures in 0.1-0.2 PSI increments if temps are outside optimal range."""

    def _handle_fuel_query(self, telemetry, analysis) -> str:
        if telemetry and telemetry.get("fuel"):
            fuel_laps = telemetry["fuel"]
            return f"""⛽ **Fuel Status:**

Current fuel load: **{fuel_laps:.1f} laps** remaining

**Strategy:**
- {"✅ Fuel is adequate" if fuel_laps > 3.0 else "⚠️ Consider fuel-saving mode"}
- Optimal consumption: 1.6-1.8 kg/lap
- Enable lean mix in Sector 3 if needed

**Tip:** Lift and coast approaching heavy braking zones to save ~0.1 kg/lap."""
        return (
            "Check your fuel readout in the HUD. Target 0.3-0.5 lap buffer at race end."
        )

    def _handle_setup_query(self, telemetry, analysis) -> str:
        track_name = (
            telemetry.get("track_name", "this circuit") if telemetry else "this circuit"
        )
        return f"""🔧 **Balanced Setup for {track_name}:**

**Baseline Settings:**
- **Aero:** Front 30-35, Rear 28-33 (adjust for track characteristics)
- **Differential:** On-throttle 65%, Off-throttle 60%
- **ARBs:** Front 6-8, Rear 5-7 (stiffer for high-speed, softer for mechanical)
- **Brake Bias:** 54-56% (tune based on entry behavior)

**Tuning Process:**
1. Validate baseline over 3-5 laps
2. Make ONE change at a time (1-2 clicks maximum)
3. Test for 2 laps minimum
4. Keep notes on changes and lap time impact

**Focus Areas:** Corner entry balance, mid-corner stability, exit traction"""

    def _handle_laptime_query(self, telemetry, analysis) -> str:
        return """⏱️ **Lap Time Improvement Focus:**

**Key Areas:**
1. **Sector Analysis:** Identify biggest time loss (use lap comparison tools)
2. **Braking Zones:** Late and progressive braking gains 0.1-0.3s per heavy zone
3. **Corner Exit:** Smooth throttle application, focus on maximizing exit speed
4. **Racing Line:** Experiment with late apex vs geometric line

**Data to Monitor:**
- Sector consistency (±0.3s variance = good)
- Speed trap deltas vs competitors
- Tyre temp evolution through stint

Use the lap comparison tool to pinpoint specific corners."""

    def _handle_strategy_query(self, telemetry, analysis) -> str:
        lap_num = telemetry.get("lap", 0) if telemetry else 0
        return f"""🎯 **Race Strategy Advice:**

{"**Current Lap:** " + str(lap_num) if lap_num > 0 else ""}

**Key Strategy Elements:**
1. **Pit Window:** Typically opens lap 12-18 (25% race distance)
2. **Tyre Delta:** Soft to Medium ~0.5-0.8s/lap, Medium to Hard ~0.3-0.5s/lap
3. **Undercut Threat:** Pit 1-2 laps before competitor to gain track position
4. **Track Position:** Worth ~0.3-0.5s/lap in dirty air

**Decision Factors:**
- Tyre wear rate (pit when >60% wear)
- Gap to cars ahead/behind
- Safety car probability
- Weather forecast

Monitor gaps and be ready to react to competitor pit stops."""

    def _handle_general_query(self, message, telemetry, analysis) -> str:
        if analysis and (analysis.get("issues") or analysis.get("recommendations")):
            response = "📊 **Current Status:**\n\n"
            if analysis.get("issues"):
                response += "**Issues Detected:**\n"
                for issue in analysis["issues"]:
                    response += f"- {issue}\n"
            if analysis.get("recommendations"):
                response += "\n💡 **Recommendations:**\n"
                for rec in analysis["recommendations"]:
                    response += f"- {rec}\n"
            return response

        # If we have rich telemetry context, summarize it and invite natural questions.
        periodic = telemetry.get("periodic") if isinstance(telemetry, dict) else None
        player_driver = (
            telemetry.get("playerDriver") if isinstance(telemetry, dict) else None
        )
        if isinstance(periodic, dict):
            entries = periodic.get("table-entries")
            player_row = None
            if isinstance(entries, list):
                player_row = next(
                    (
                        r
                        for r in entries
                        if r.get("driver-info", {}).get("is-player") is True
                    ),
                    None,
                )

            if isinstance(player_row, dict):
                di = player_row.get("driver-info", {})
                li = player_row.get("lap-info", {})
                ti = player_row.get("tyre-info", {})
                fi = player_row.get("fuel-info", {})
                pos = di.get("position")
                name = di.get("name", "You")
                lap = (
                    li.get("lap-num")
                    or li.get("current-lap")
                    or periodic.get("current-lap")
                )
                compound = ti.get("visual-tyre-compound")
                tyre_age = ti.get("tyre-age")
                tyre_life = ti.get("tyre-life-remaining")
                fuel_laps = fi.get("fuel-remaining-laps")

                summary = "📡 **Live Telemetry Summary:**\n\n"
                summary += f"- Driver: {name}\n"
                if isinstance(pos, int):
                    summary += f"- Position: P{pos}\n"
                if lap is not None:
                    summary += f"- Lap: {lap}\n"
                if compound:
                    summary += f"- Tyre: {compound}"
                    if tyre_age is not None:
                        summary += f" (age {tyre_age})"
                    if tyre_life is not None:
                        summary += f", ~{tyre_life} laps left"
                    summary += "\n"
                if fuel_laps is not None:
                    summary += f"- Fuel remaining: ~{fuel_laps} laps\n"

                summary += "\nAsk naturally, e.g.:\n"
                summary += "- “What should I do for the next 5 laps?”\n"
                summary += "- “Am I in danger from behind / can I undercut?”\n"
                summary += "- “Where am I losing time and why?”\n"
                return summary

        if isinstance(player_driver, dict):
            name = player_driver.get("driver-name", "You")
            pos = player_driver.get("position")
            compound = player_driver.get("tyre-info", {}).get("visual-tyre-compound")
            return (
                f"📡 I’ve got your live context ({name}"
                + (f", P{pos}" if isinstance(pos, int) else "")
                + (f", {compound}" if compound else "")
                + "). Ask anything and I’ll answer from telemetry."
            )

        return "Ask anything about strategy, pace, tyres, or setup—I’ll answer from telemetry when available."
