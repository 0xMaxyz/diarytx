import { Ai } from "./vendor/@cloudflare/ai.js";

export default {
    async fetch(request, env) {
        let chat;
        const url = request.url.split("/").filter((i) => i);
        const key = "sample key:";
        let prompt;
        if (url.length == 3) {
            prompt = decodeURI(url[2]);
            if (prompt.startsWith(key)) {
                prompt = prompt.split(key).filter((i) => i);
                chat = {
                    messages: [
                        {
                            role: "system",
                            content:
                                "Classify the following input text into one of the following mood categories: Angry, Anxious, Bored, Calm, Confused, Disappointed, Energetic, Excited, Grateful, Happy, Hopeful, Insecure, Jealous, Lonely, Motivated, Overwhelmed, Peaceful, Proud, Reflective, Sad. Only output the identified category, with no additional symbols or words.",
                        },
                        { role: "user", content: prompt[0] },
                    ],
                };
            }
        }
        const tasks = [];
        const ai = new Ai(env.AI);

        const response = await ai.run("@cf/meta/llama-2-7b-chat-fp16", chat);
        tasks.push({ inputs: chat, response });

        return Response.json(tasks);
    },
};
