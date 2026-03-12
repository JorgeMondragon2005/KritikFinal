# build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /source

# copy shared project first
COPY src/Kritik.Shared/*.csproj src/Kritik.Shared/
RUN dotnet restore "src/Kritik.Shared/Kritik.Shared.csproj"

# copy backend project
COPY src/Kritik.Backend/*.csproj src/Kritik.Backend/
RUN dotnet restore "src/Kritik.Backend/Kritik.Backend.csproj"

# copy everything else and build app
COPY src/Kritik.Shared/ src/Kritik.Shared/
COPY src/Kritik.Backend/ src/Kritik.Backend/

WORKDIR /source/src/Kritik.Backend
RUN dotnet publish -c release -o /app --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app ./
ENTRYPOINT ["dotnet", "Kritik.Backend.dll"]
