# Godot Multiplayer Platform

This project serves as an example implementation of a simple multiplayer system in Godot 4 using Godot High-Level Multiplayer. It includes some of my favorite design patterns that I make use of in my own projects. You can use this either as a template to start your own game, or just as supplementary material that you can refer to as needed. This version of the project has no dependencies outside of Godot 4.

## Overview

This is a remarkably simple example project that includes the following functionality:

- Hosting and joining lobbies using `ENetMultiplayerPeer`
- LAN lobby discovery using `UDPServer` and `UDPPacketPeer`
- Synchronized player character spawning
- Synchronized player character movement
- Synchronized level loading
- Lobby management (kicking and banning)

## Topology

If you're learning game networking, it's important to understand that this approach is not the only available or correct option. Exposing your players systems' to external traffic is always a big responsibility. Consider the specific needs of your game before commiting to any design pattern.

This example project makes use of the "host-client" model, where one player hosts a game and their computer is used as the server which other players connect to as clients on their respective systems. The host is authoritative over most of the in-game systems, for example the `LevelLoader`, and the clients are authoritative over the players they control. Here are some quick notes on this approach:

Pros:
- Easy to setup
- Not dependant on an external server
- Suitable (and commonly used) for co-op, party, and "friendslop" games

Cons:
- Not fully server-authoritative
- No way to prevent cheating
- Not suitable for competitive games

As of writing, there is no NAT traversal method implemented as part of this project, so you'll have to make use of a LAN connection or implement some solution yourself. The `steam-backend` branch is a WIP.

## Systems

Here is a brief overview of the systems included in this project and how they work. For details on the implementation, I suggest reading the code for yourself.

### `GameMaster`

`GameMaster` is the root scene of this project, and it always stays the root. It is responsible for managing the `LevelLoader` and `PlayerSpawner`, which we'll talk about later. Basically, it manages the high-level state of the game scenes. We take this approach because of well-known issues having to do with the `change_scene_to` methods when using multiplayer, which you can read more about [here](https://godotengine.org/article/multiplayer-in-godot-4-0-scene-replication/).

### `LevelLoader`

The `LevelLoader`, as its name suggests, is responsible for loading and unloading level scenes. `LevelLoader` maintains a `Dictionary` called `LEVEL_DICT`, which stores a list of key-value pairs for level scenes and their respective keys. For example, when we host a game, `GameMaster` calls `level_loader.load_level('example')`, where "example" is the key associated with the provided scene `example.tscn`. When another peer joins, the host will send the joining peer the key for the level currently loaded so that peer can load the correct level as well. To synchronously load a level for all peers, have the host call `LevelLoader.load_level.rpc(<key>)`

### `PlayerSpawner`

The `PlayerSpawner` handles the spawning and despawning of player characters. It extends `MultiplayerSpawner` and takes advantage of its automatic spawning and despawning, which comes from the authority (host). When we host a game, we call `player_spawner.spawn_player(1)` to spawn the host player. When another peer joins, the host spawns a player character for that peer, and it is propagated to all other peers through the `MultiplayerSpawner` functionality. When a peer disconnects, much the same, the host deletes that player character and that deletion is carried over to all other peers.

### `MultiplayerService`

`MultiplayerService` is a high-level interface masking a `MultiplayerBackend`, which we'll talk about later. It exposes signals so that the game state can respond to events like lobby joining and leaving, and methods to initiate those events. The majority of the logic simply acts as a relay between the `MultiplayerBackend` and the rest of the game. The reason we do this as opposed to just exposing the `MultiplayerBackend` directly is so that we can select or swap out our `MultiplayerBackend` at runtime.

### `MultiplayerBackend`

`MultiplayerBackend` is an abstract template defining the baseline connection logic needed for most multiplayer games. This project includes `ENetBackend` as an example extension, but `MultiplayerBackend` can be extended to support any backend, such as Steam using Gramps' [`SteamMultiplayerPeer`](https://godotsteam.com/tutorials/multiplayer_peer/).

## Branches

The branches off of `master` in this repository represent additions that depend on addons, and thus don't make sense to include on the main branch. At time of writing this includes `steam-backend`, which is an extension of `MultiplayerBackend` using Gramps' [`SteamMultiplayerPeer`](https://godotsteam.com/tutorials/multiplayer_peer/).

## Planned Features

I want to include examples of other common features, here is what I have planned:

- Proximity Voice Chat
- Interaction System

If there is a feature you'd like to see included, feel free to open an issue or pull request.
