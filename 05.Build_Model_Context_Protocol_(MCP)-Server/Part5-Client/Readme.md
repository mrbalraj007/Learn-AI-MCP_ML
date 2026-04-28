
**MCP Clients**

· MCP clients are instantiated by host applications to communicate with
particular MCP servers

· The host is the application users interact with, while clients are the protocol-
level components that enable server connections

· Clients may provide several features to servers that allow server authors to
build richer interactions

## Client Primitives

| Building Block | Purpose | Who Triggers It | Real-World Example |
|---------------|--------|----------------|-------------------|
| Sampling | Request language model completions | Server | Request AI completions for data analysis, text generation, or other server-side AI tasks |
| Logging | Send log messages to clients | Server | Receive server log messages for debugging, monitoring, and diagnostics |
| Elicitation | Request specific information from users | Client | Request traveler details for flight bookings, special hotel requests, or emergency contact information |
| Roots | Communicate filesystem access boundaries to servers | Client | Provide directories (file URIs) where servers can safely operate, restricting access to specified folders |


**Sampling**

· Sampling allows servers to request language model completions through the client

· Server can request the client who has Al model access to handle any Al-dependent tasks on its behalf

· Sampling puts the client in complete control of user permissions and security measures

· Every sampling request needs explicit user consent. Clients show what the server wants to
analyze and why. Users can approve, deny, or modify requests

· Clients display the exact prompt, model selection, and token limits. Users review Al responses before
they return to the server

· Sampling requests are isolated from the main conversation context by default. Servers cannot access
user conversations


**Sampling**

Example: Business Travel Planning

. When a user asks "**Book me the best flight to Barcelona next month**," the server tool
"findFlights" will need Al assistance to evaluate complex trade-offs as per user preferences

· The server tool queries airline APIs and gathers "x" number of flight options

· It then requests Al assistance to analyze these options: "*Analyze these flight options and
recommend the best choice as per the User preferences: morning departure, max 1 layover.*"

. The client asks the user: "*Allow sampling request?*"

· Upon approval, the Al evaluates trade-offs-like cheaper red-eye flights versus convenient
morning departures

· This analysis is shared with the server tool after user review

. **The tool uses this analysis to present the top three recommendations**



**Logging**

· Allows servers to send log messages to clients for debugging, monitoring, and auditing

· Triggered by the server during operation or error handling

· Helps clients receive real-time feedback on server activities

· Supports diagnostics by capturing important events or errors

· Enables performance monitoring and usage tracking

· Improves transparency between server and client

· Facilitates faster issue resolution and debugging

. Enhances `reliability` and `trust` in the system


Logging
Example: Business Travel Planning

. When a flight booking fails, the server logs the error and sends it to the client's
dashboard for immediate attention, enabling quick troubleshooting and customer
support


**Roots**

· Clients define filesystem boundaries so servers only access relevant travel data folders

. Triggered by the client to specify safe directories

· Provides servers access to folders containing user itineraries, travel documents, and
preferences

· Prevents servers from accessing unrelated files on the client's device, maintaining
privacy and security

· Helps servers efficiently locate and use only necessary data for travel planning

**Roots
**
Example: Business Travel Planning

. The client exposes a "TravelDocs" directory as a root, allowing the server to read itinerary PDFs
and update booking records without risking access to personal files outside this folder

**Elicitation**

· Elicitation enables servers to request specific information from users during
interactions, creating more dynamic and responsive workflows

· **Servers can request specific data when needed**, users provide information through
appropriate UI, and servers continue processing with the newly acquired context

· Elicitation interactions are designed to be clear, contextual, and respectful of user
autonomy:

· Clients display elicitation requests with clear context about which server is asking, why the information is
needed, and how it will be used.

· Users can provide the requested information through appropriate UI controls (text fields, dropdowns,
checkboxes) OR decline to provide information with optional explanation, or cancel the entire operation

· Users review data before sending

**Elicitation**

Example: Business Travel Planning

· The server elicits booking confirmation with a structured request that includes the trip summary
(Barcelona flights June 15-22, beachfront hotel, total $3,000)

· As the booking progresses, the server ask for traveler details for flight bookings, special requests for
the hotel, or emergency contact information

https://www.youtube.com/watch?v=zcaVY4gvMkY&list=PLrDJzKfz9AUvJ6LipcrxWZmMZDY2z_Tkj&index=5