Environment Setup
· Provision a single Windows Server 2025 Base, c5.xlarge VM on AWS
OR
· Use your laptop/desktop

· Download
· .NET 8 SDK or higher
· Visual Studio Code
· Claude for Desktop
· Install
· .NET 8 SDK or higher
Confirm that the dotnet version is above 8
Run command : dotnet -- version
· Visual Studio Code
Install C# dev Extension
· Claude for Desktop

Note : I have completed these steps


Create and set up your project

· Create a new directory for our project
mkdir weather
cd weather

· Initialize a new C# project
dotnet new console

· Open the project in VS Code

· Add the Model Context Protocol SDK NuGet package
dotnet add package ModelContextProtocol -- prerelease

· Add the .NET Hosting NuGet package
dotnet add package Microsoft.Extensions.Hosting

.


Reference URLs:
- [dotnet](https://dotnet.microsoft.com/en-us/download)
- [vscode](https://code.visualstudio.com/)
- [Claude Desktop](https://claude.com/download)
- [MCP Server](https://modelcontextprotocol.io/docs/develop/build-server)
