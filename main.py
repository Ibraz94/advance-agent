import os  # For accessing environment variables
import chainlit as cl  # Web UI framework for chat applications
from dotenv import load_dotenv  # For loading environment variables
from typing import Optional, Dict  # Type hints for better code clarity
from agents import Agent, Runner, AsyncOpenAI, OpenAIChatCompletionsModel
from agents.tool import function_tool
import requests

# Load environment variables from .env file
load_dotenv()

# Get Gemini API key from environment variables
gemini_api_key = os.getenv("GEMINI_API_KEY")

# Initialize OpenAI provider with Gemini API settings
provider = AsyncOpenAI(
    api_key=gemini_api_key,
    base_url="https://generativelanguage.googleapis.com/v1beta/openai",
)

# Configure the language model
model = OpenAIChatCompletionsModel(model="gemini-2.0-flash", openai_client=provider)


@function_tool("mobile_data")
def get_mobile_data() -> str:
    """
    Fetches data about mobile phones from the REST API.

    This function makes a GET request to the mobile phones API endpoint
    to retrieve information about various mobile devices including their
    specifications, prices, and other details.

    Returns:
        str: JSON string containing mobile phones data
    """
    try:
        response = requests.get("https://api.restful-api.dev/objects")
        if response.status_code == 200:
            return response.text
        else:
            return f"Error fetching data: Status code {response.status_code}"
    except Exception as e:
        return f"Error fetching data: {str(e)}"


agent = Agent(
    name="Mobile Data Agent",
    instructions="""You are a Mobile Data Agent designed to provide information about mobile phones.

Your responsibilities:
1. Greet users warmly when they say hello (respond with 'Hi, I am mobile data agent')
2. Say goodbye appropriately when users leave (respond with 'Good Bye')
3. When users request information about mobile phones, use the get_mobile_data tool to retrieve and share mobile phone specifications and details
4. For any questions not related to greetings or mobile phones, politely explain: 'I'm only able to provide greetings and information about mobile phones. I can't answer other questions at this time.'
Always maintain a friendly, professional tone and provide accurate mobile phone information within your defined scope.""",
    model=model,
    tools=[get_mobile_data],
)


# Handler for when a new chat session starts
@cl.on_chat_start
async def handle_chat_start():

    cl.user_session.set("history", [])  # Initialize empty chat history

    await cl.Message(
        content=""
    ).send()  # Send welcome message


# Handler for incoming chat messages
@cl.on_message
async def handle_message(message: cl.Message):

    history = cl.user_session.get("history")  # Get chat history from session

    history.append(
        {"role": "user", "content": message.content}
    )  # Add user message to history

    result = await cl.make_async(Runner.run_sync)(agent, input=history)

    response_text = result.final_output
    await cl.Message(content=response_text).send()

    history.append({"role": "assistant", "content": response_text})
    cl.user_session.set("history", history)