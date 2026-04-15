require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const fs = require('fs');

async function test() {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const visionModel = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  
  // Create a dummy 1x1 pixel JPEG in base64
  const base64Image = "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=";
  
  const fullPrompt =
    `Bạn là trợ lý AI...\n\n` +
    `Bạn PHẢI trả về JSON hợp lệ theo schema sau (KHÔNG thêm text ngoài JSON):\n` +
    `{\n` +
    `  "answer": "string (plain text, không markdown)",\n` +
    `  "action": { "type": "search_courts|view_schedule|view_expense|cancel_booking|none", "sport": "optional" },\n` +
    `  "used_sources": ["S1","S2"]\n` +
    `}\n\n` +
    `USER_ASK: con gì đây`;

  try {
    const result = await visionModel.generateContent({
      contents: [{
        role: 'user',
        parts: [
          { text: fullPrompt }, 
          { inlineData: { data: base64Image, mimeType: "image/jpeg" } }
        ]
      }],
      generationConfig: { responseMimeType: "application/json" }
    });
    console.log("SUCCESS:", result.response.text());
  } catch(e) {
    console.error("ERROR 1:", e);
  }
}
test();
