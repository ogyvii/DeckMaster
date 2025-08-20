# NFT Card Battle Game

A collectible trading card game built on the Stacks blockchain using Clarity smart contracts. Players can collect NFT cards, build decks, and battle against other players in strategic turn-based combat.

## Overview

This project implements a fully-featured digital trading card game where:
- Each card is a unique NFT with stats and abilities
- Players open booster packs to collect cards
- Cards can be organized into custom decks
- Players battle using their decks in turn-based combat
- Cards gain experience and level up through battles
- Tournament system for competitive play

## Core Features

### 🎴 Card System
- **NFT Cards**: Each card is a unique blockchain asset with ownership tracking
- **Card Templates**: Define base stats, abilities, and rarity for different card types
- **Rarity System**: Common, Rare, Epic, and Legendary cards
- **Element Types**: Fire, Water, Earth, Air, and Neutral elements
- **Card Types**: Creatures, Spells, and Artifacts
- **Leveling**: Cards gain experience and level up through battles

### 📦 Booster Pack System
- **Pack Types**: Starter, Standard, and Premium packs
- **Guaranteed Rarity**: Some packs guarantee rare or higher cards
- **Random Generation**: Cards are randomly generated when packs are opened
- **STX Payment**: Purchase packs using STX tokens

### ⚔️ Battle System
- **Turn-Based Combat**: Strategic gameplay with energy management
- **Deck Building**: Create custom decks with up to 30 cards
- **Field Positioning**: Deploy creatures to battlefield positions
- **Health & Energy**: Manage player health and energy resources
- **Victory Conditions**: Reduce opponent's health to zero

### 🏆 Tournament System
- **Organized Competitions**: Create tournaments with entry fees
- **Prize Pools**: Winners receive accumulated prize money
- **Ranking System**: Players earn ranking points through victories
- **Statistics Tracking**: Comprehensive battle and collection stats

## Smart Contract Architecture

### Data Structures

#### Card Templates
```clarity
{
  name: (string-ascii 32),
  description: (string-ascii 128),
  rarity: (string-ascii 16),
  element: (string-ascii 16),
  cost: uint,
  attack: uint,
  health: uint,
  special-ability: (string-ascii 64),
  card-type: (string-ascii 16),
  set-id: uint
}
```

#### Card Instances (NFTs)
```clarity
{
  template-id: uint,
  owner: principal,
  level: uint,
  experience: uint,
  in-deck: bool,
  mint-block: uint,
  battle-count: uint,
  win-count: uint
}
```

#### Battle State
```clarity
{
  player1: principal,
  player2: principal,
  current-turn: principal,
  player1-health: uint,
  player2-health: uint,
  player1-energy: uint,
  player2-energy: uint,
  status: (string-ascii 16),
  winner: (optional principal)
}
```

## Key Functions

### Card Management
- `create-card-template`: Define new card types (owner only)
- `open-booster-pack`: Purchase and open card packs
- `get-card`: Retrieve card information
- `get-player-collection`: View player's card collection

### Deck Building
- `create-deck`: Build a custom deck from owned cards
- `get-player-deck`: Retrieve deck information
- Minimum 20 cards, maximum 30 cards per deck

### Battle System
- `challenge-battle`: Initiate a battle with another player
- `play-card`: Deploy cards to the battlefield
- `attack-with-card`: Attack opponents or their creatures
- `end-turn`: Pass turn to opponent
- `get-battle`: View current battle state

### Tournament System
- `create-tournament`: Set up competitive tournaments (owner only)
- Entry fees and prize pools
- Participant registration and management

## Game Mechanics

### Energy System
- Players start with 1 energy per turn
- Energy increases each turn (max 10)
- Cards require energy to play based on their cost

### Combat Rules
- Creatures have attack and health values
- Attacking reduces target's health by attacker's attack value
- Creatures with 0 health are destroyed
- Direct player attacks reduce player health
- First player to reach 0 health loses

### Card Progression
- Cards gain 10 experience per battle won
- Level up when experience reaches level × 100
- Higher level cards may gain stat bonuses

### Deck Building Rules
- 20-30 cards per deck
- Must own all cards in deck
- Cards can only be in one active deck at a time

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for purchasing packs
- Clarity development environment for deployment

### Deployment
1. Deploy the contract to Stacks testnet or mainnet
2. Initialize card templates using `create-card-template`
3. Create booster pack types using `create-booster-pack`
4. Set pack prices and game parameters

### Playing the Game
1. **Collect Cards**: Purchase and open booster packs
2. **Build Decks**: Create decks from your card collection
3. **Battle**: Challenge other players to strategic battles
4. **Progress**: Level up cards and improve your collection
5. **Compete**: Participate in tournaments for prizes

## Contract Constants

- **Pack Price**: 0.5 STX per pack (configurable)
- **Max Deck Size**: 30 cards
- **Max Hand Size**: 7 cards
- **Starting Health**: 30 HP per player
- **Battle Positions**: 5 creature positions max

## Error Codes

- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Unauthorized operation
- `u103`: Invalid battle state
- `u104`: Insufficient energy
- `u105`: Deck is full
- `u106`: Invalid card
- `u107`: Pack sold out
- `u108`: Invalid deck configuration

## Security Features

- **Ownership Verification**: All operations verify card ownership
- **Battle Validation**: Turn-based validation prevents cheating
- **Access Control**: Admin functions restricted to contract owner
- **State Consistency**: Atomic operations maintain game state integrity

## Future Enhancements

- **Special Abilities**: Implement card-specific special abilities
- **More Card Types**: Expand beyond creatures, spells, artifacts
- **Advanced Tournaments**: Bracket-style tournament progression
- **Trading System**: Direct player-to-player card trading
- **Seasonal Events**: Limited-time cards and tournaments
- **Guild System**: Team-based competitions and rewards

## Development

### Testing
- Write comprehensive unit tests for all functions
- Test edge cases and error conditions
- Verify randomness and fairness in pack generation

### Optimization
- Consider gas costs for complex operations
- Optimize data structures for efficiency
- Implement batching for multiple operations
