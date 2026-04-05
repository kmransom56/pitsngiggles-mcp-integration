#!/usr/bin/env python3
"""
F1 23 Race Engineer MCP Server
Provides AI-powered race engineering analysis for Pits N Giggles telemetry
"""

import asyncio
import json
import logging
from typing import Any, Dict, List, Optional
from datetime import datetime
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import httpx
from contextlib import asynccontextmanager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class TelemetryData(BaseModel):
    """Telemetry data from Pits N Giggles"""
    lap: Optional[int] = None
    sector: Optional[int] = None
    speed: Optional[float] = None
    throttle: Optional[float] = None
    brake: Optional[float] = None
    steering: Optional[float] = None
    tyre_temps: Optional[Dict[str, float]] = None
    tyre_wear: Optional[Dict[str, float]] = None
    fuel: Optional[float] = None
    position: Optional[int] = None
    session_type: Optional[str] = None


class ChatMessage(BaseModel):
    """Chat message from the frontend"""
    message: str
    telemetry: Optional[TelemetryData] = None


class RaceEngineerResponse(BaseModel):
    """Response from the race engineer AI"""
    response: str
    analysis: Optional[Dict[str, Any]] = None
    recommendations: Optional[List[str]] = None


class F1RaceEngineer:
    """F1 Race Engineer AI Agent"""
    
    def __init__(self, llm_endpoint: str = None, llm_api_key: str = None):
        self.llm_endpoint = llm_endpoint
        self.llm_api_key = llm_api_key
        self.telemetry_history = []
        self.conversation_history = []
        
    def analyze_telemetry(self, telemetry: TelemetryData) -> Dict[str, Any]:
        """Analyze telemetry data and identify issues"""
        analysis = {
            "timestamp": datetime.now().isoformat(),
            "issues": [],
            "recommendations": []
        }
        
        if telemetry.tyre_temps:
            temps = telemetry.tyre_temps
            avg_temp = sum(temps.values()) / len(temps)
            temp_diff = max(temps.values()) - min(temps.values())
            
            if temp_diff > 15:
                analysis["issues"].append(f"Tyre temperature imbalance: {temp_diff:.1f}°C difference")
                if temps.get("FL", 0) > avg_temp + 10:
                    analysis["recommendations"].append("Reduce front wing angle by 1-2 clicks")
                elif temps.get("RL", 0) > avg_temp + 10:
                    analysis["recommendations"].append("Increase rear anti-roll bar stiffness")
        
        if telemetry.tyre_wear:
            wear = telemetry.tyre_wear
            avg_wear = sum(wear.values()) / len(wear)
            
            if avg_wear > 60:
                analysis["issues"].append(f"High tyre wear: {avg_wear:.1f}%")
                analysis["recommendations"].append("Consider pit stop within 5 laps")
        
        if telemetry.throttle is not None and telemetry.brake is not None:
            if telemetry.throttle > 0.1 and telemetry.brake > 0.1:
                analysis["issues"].append("Simultaneous throttle and brake application detected")
                analysis["recommendations"].append("Focus on smoother input transitions")
        
        return analysis
    
    async def generate_response(self, message: str, telemetry: Optional[TelemetryData] = None) -> RaceEngineerResponse:
        """Generate AI response using LLM"""
        
        analysis = None
        if telemetry:
            analysis = self.analyze_telemetry(telemetry)
            self.telemetry_history.append({
                "telemetry": telemetry.dict(),
                "analysis": analysis
            })
        
        context = self._build_context(message, telemetry, analysis)
        
        if self.llm_endpoint and self.llm_api_key:
            try:
                response_text = await self._call_llm(context)
            except Exception as e:
                logger.error(f"LLM call failed: {e}")
                response_text = self._generate_fallback_response(message, analysis)
        else:
            response_text = self._generate_fallback_response(message, analysis)
        
        recommendations = analysis.get("recommendations", []) if analysis else []
        
        return RaceEngineerResponse(
            response=response_text,
            analysis=analysis,
            recommendations=recommendations
        )
    
    def _build_context(self, message: str, telemetry: Optional[TelemetryData], analysis: Optional[Dict]) -> str:
        """Build context for LLM"""
        context = """You are an expert F1 Race Engineer for F1 23. Analyze telemetry and provide professional setup/tuning advice.

Key tuning principles:
- Aero: Increase front wing for turn-in grip; increase rear for stability
- Differential: Lower on-throttle for exit rotation; lower off-throttle for entry rotation
- Suspension: Stiffen rear ARB for oversteer; stiffen front ARB for understeer
- Brake Bias: Move forward for oversteer under braking; move rear for understeer

"""
        
        if telemetry:
            context += f"\nCurrent Telemetry:\n{json.dumps(telemetry.dict(), indent=2)}\n"
        
        if analysis:
            context += f"\nAutomated Analysis:\n{json.dumps(analysis, indent=2)}\n"
        
        context += f"\nDriver Question: {message}\n\nProvide concise, actionable advice:"
        
        return context
    
    async def _call_llm(self, context: str) -> str:
        """Call external LLM API"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                self.llm_endpoint,
                headers={
                    "Authorization": f"Bearer {self.llm_api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "gpt-4",
                    "messages": [
                        {"role": "system", "content": "You are an expert F1 Race Engineer."},
                        {"role": "user", "content": context}
                    ],
                    "temperature": 0.7,
                    "max_tokens": 300
                }
            )
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"]
    
    def _generate_fallback_response(self, message: str, analysis: Optional[Dict]) -> str:
        """Generate response when LLM is not available"""
        message_lower = message.lower()
        
        if analysis and analysis.get("recommendations"):
            return f"Based on telemetry analysis: {analysis['recommendations'][0]}"
        
        if "understeer" in message_lower:
            return "To reduce understeer: Increase front wing angle (+1-2 clicks), soften front ARB, or increase front tyre pressure by 0.1-0.2 PSI."
        
        elif "oversteer" in message_lower:
            return "To reduce oversteer: Increase rear wing angle (+1-2 clicks), stiffen rear ARB, or reduce rear tyre pressure by 0.1 PSI."
        
        elif any(word in message_lower for word in ["pit", "tyre", "tire", "degradation"]):
            return "Monitor tyre wear and temperature. Optimal pit window is typically when wear exceeds 55-60% or temps become unstable."
        
        elif "fuel" in message_lower:
            return "Check fuel consumption rate. If running rich, consider fuel-saving mode in final sectors. Target 0.2-0.5 lap buffer at race end."
        
        elif any(word in message_lower for word in ["setup", "balance"]):
            return "Start with baseline setup. Make small incremental changes (1 click at a time). Test and validate each change before proceeding."
        
        elif any(word in message_lower for word in ["sector", "lap", "time"]):
            return "Focus on corner entry and exit phases. Smooth throttle application and trail braking are key to reducing lap times."
        
        else:
            return "I can help with: car setup, handling balance, tyre strategy, fuel management, and lap time analysis. What specific area would you like to improve?"


class ConnectionManager:
    """Manage WebSocket connections"""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"Client connected. Total connections: {len(self.active_connections)}")
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
        logger.info(f"Client disconnected. Total connections: {len(self.active_connections)}")
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_json(message)
    
    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to client: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    logger.info("Starting F1 Race Engineer MCP Server...")
    yield
    logger.info("Shutting down F1 Race Engineer MCP Server...")


app = FastAPI(
    title="F1 Race Engineer MCP Server",
    description="AI-powered race engineering for F1 23 via Pits N Giggles",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

race_engineer = F1RaceEngineer()
connection_manager = ConnectionManager()


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "F1 Race Engineer MCP Server",
        "version": "1.0.0",
        "connections": len(connection_manager.active_connections)
    }


@app.get("/health")
async def health():
    """Health check for monitoring"""
    return {"status": "healthy"}


@app.post("/mcp/chat")
async def chat_endpoint(chat_message: ChatMessage) -> RaceEngineerResponse:
    """HTTP endpoint for chat messages"""
    try:
        response = await race_engineer.generate_response(
            chat_message.message,
            chat_message.telemetry
        )
        return response
    except Exception as e:
        logger.error(f"Error processing chat message: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.websocket("/mcp/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time communication"""
    await connection_manager.connect(websocket)
    
    try:
        while True:
            data = await websocket.receive_json()
            
            message_type = data.get("type", "chat")
            
            if message_type == "chat":
                message = data.get("message", "")
                telemetry_data = data.get("telemetry")
                
                telemetry = None
                if telemetry_data:
                    telemetry = TelemetryData(**telemetry_data)
                
                response = await race_engineer.generate_response(message, telemetry)
                
                await connection_manager.send_personal_message({
                    "type": "response",
                    "data": response.dict()
                }, websocket)
            
            elif message_type == "telemetry":
                telemetry = TelemetryData(**data.get("data", {}))
                analysis = race_engineer.analyze_telemetry(telemetry)
                
                if analysis.get("issues"):
                    await connection_manager.send_personal_message({
                        "type": "alert",
                        "data": analysis
                    }, websocket)
    
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        connection_manager.disconnect(websocket)


@app.get("/mcp/telemetry/history")
async def get_telemetry_history():
    """Get telemetry history"""
    return {
        "history": race_engineer.telemetry_history[-50:]
    }


@app.post("/mcp/analyze")
async def analyze_telemetry(telemetry: TelemetryData):
    """Analyze telemetry data"""
    analysis = race_engineer.analyze_telemetry(telemetry)
    return {"analysis": analysis}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8765,
        log_level="info"
    )
