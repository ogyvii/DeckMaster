;; NFT Card Battle Game Contract
;; Collectible trading card game with deck building and battles

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-battle (err u103))
(define-constant err-insufficient-energy (err u104))
(define-constant err-deck-full (err u105))
(define-constant err-invalid-card (err u106))
(define-constant err-pack-sold-out (err u107))
(define-constant err-invalid-deck (err u108))

;; Data Variables
(define-data-var next-card-id uint u1)
(define-data-var next-battle-id uint u1)
(define-data-var next-pack-id uint u1)
(define-data-var pack-price uint u500000) ;; 0.5 STX per pack
(define-data-var max-deck-size uint u30)
(define-data-var max-hand-size uint u7)

;; Card template structure
(define-map card-templates 
  uint 
  {
    name: (string-ascii 32),
    description: (string-ascii 128),
    rarity: (string-ascii 16), ;; "common", "rare", "epic", "legendary"
    element: (string-ascii 16), ;; "fire", "water", "earth", "air", "neutral"
    cost: uint,
    attack: uint,
    health: uint,
    special-ability: (string-ascii 64),
    card-type: (string-ascii 16), ;; "creature", "spell", "artifact"
    set-id: uint
  }
)

;; Individual card instances (NFTs)
(define-map cards 
  uint 
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
)

;; Player card collections
(define-map player-collections 
  principal 
  {
    card-ids: (list 200 uint),
    total-cards: uint,
    rare-cards: uint,
    epic-cards: uint,
    legendary-cards: uint,
    collection-value: uint
  }
)

;; Player decks
(define-map player-decks 
  {player: principal, deck-id: uint} 
  {
    name: (string-ascii 32),
    card-ids: (list 30 uint),
    deck-size: uint,
    element-focus: (string-ascii 16),
    win-rate: uint,
    battles-played: uint,
    is-active: bool
  }
)

;; Card battles
(define-map card-battles 
  uint 
  {
    player1: principal,
    player2: principal,
    player1-deck: uint,
    player2-deck: uint,
    current-turn: principal,
    turn-number: uint,
    player1-health: uint,
    player2-health: uint,
    player1-energy: uint,
    player2-energy: uint,
    status: (string-ascii 16), ;; "active", "finished"
    winner: (optional principal),
    battle-type: (string-ascii 16), ;; "ranked", "casual", "tournament"
    start-block: uint
  }
)

;; Battle field state
(define-map battle-field 
  {battle-id: uint, position: uint} 
  {
    card-id: uint,
    owner: principal,
    current-health: uint,
    current-attack: uint,
    can-attack: bool
  }
)

;; Player hand during battle
(define-map battle-hands 
  {battle-id: uint, player: principal} 
  {
    hand-cards: (list 7 uint),
    hand-size: uint,
    cards-played: uint,
    energy-spent: uint
  }
)

;; Booster pack system
(define-map booster-packs 
  uint 
  {
    pack-type: (string-ascii 16), ;; "starter", "standard", "premium"
    card-count: uint,
    guaranteed-rare: bool,
    price: uint,
    available-count: uint,
    set-id: uint
  }
)

;; Player statistics
(define-map player-stats 
  principal 
  {
    total-battles: uint,
    wins: uint,
    losses: uint,
    ranking-points: uint,
    highest-rank: uint,
    cards-collected: uint,
    packs-opened: uint,
    tournaments-won: uint
  }
)

;; Initialize card templates (owner only)
(define-public (create-card-template (template-id uint) (name (string-ascii 32)) (description (string-ascii 128)) (rarity (string-ascii 16)) (element (string-ascii 16)) (cost uint) (attack uint) (health uint) (special-ability (string-ascii 64)) (card-type (string-ascii 16)) (set-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set card-templates template-id
      {
        name: name,
        description: description,
        rarity: rarity,
        element: element,
        cost: cost,
        attack: attack,
        health: health,
        special-ability: special-ability,
        card-type: card-type,
        set-id: set-id
      }
    )
    (ok true)
  )
)

;; Create booster pack type
(define-public (create-booster-pack (pack-id uint) (pack-type (string-ascii 16)) (card-count uint) (guaranteed-rare bool) (price uint) (available-count uint) (set-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set booster-packs pack-id
      {
        pack-type: pack-type,
        card-count: card-count,
        guaranteed-rare: guaranteed-rare,
        price: price,
        available-count: available-count,
        set-id: set-id
      }
    )
    (ok true)
  )
)

;; Open booster pack (simplified to avoid circular dependencies)
(define-public (open-booster-pack (pack-id uint))
  (let 
    (
      (pack (unwrap! (map-get? booster-packs pack-id) err-not-found))
      (player-collection (default-to 
                          {card-ids: (list), total-cards: u0, rare-cards: u0, epic-cards: u0, legendary-cards: u0, collection-value: u0}
                          (map-get? player-collections tx-sender)))
      (player-stats-data (default-to 
                          {total-battles: u0, wins: u0, losses: u0, ranking-points: u1000, highest-rank: u0, cards-collected: u0, packs-opened: u0, tournaments-won: u0}
                          (map-get? player-stats tx-sender)))
    )
    
    (asserts! (> (get available-count pack) u0) err-pack-sold-out)
    
    ;; Transfer payment
    (try! (stx-transfer? (get price pack) tx-sender contract-owner))
    
    ;; Create one card (simplified from pack generation)
    (let 
      (
        (new-card-id (var-get next-card-id))
        (template-id (generate-random-template pack-id))
      )
      ;; Create new card instance
      (map-set cards new-card-id
        {
          template-id: template-id,
          owner: tx-sender,
          level: u1,
          experience: u0,
          in-deck: false,
          mint-block: block-height,
          battle-count: u0,
          win-count: u0
        }
      )
      
      ;; Update pack availability
      (map-set booster-packs pack-id
        (merge pack {available-count: (- (get available-count pack) u1)})
      )
      
      ;; Update player collection
      (map-set player-collections tx-sender
        (merge player-collection 
          {
            card-ids: (unwrap! (as-max-len? (append (get card-ids player-collection) new-card-id) u200) err-deck-full),
            total-cards: (+ (get total-cards player-collection) u1)
          }
        )
      )
      
      ;; Update player statistics
      (map-set player-stats tx-sender
        (merge player-stats-data 
          {
            cards-collected: (+ (get cards-collected player-stats-data) u1),
            packs-opened: (+ (get packs-opened player-stats-data) u1)
          }
        )
      )
      
      (var-set next-card-id (+ new-card-id u1))
      (ok new-card-id)
    )
  )
)

;; Generate random template ID for pack
(define-private (generate-random-template (pack-id uint))
  (let 
    (
      (seed (+ pack-id block-height))
      (template-range u50) ;; Assuming 50 templates available
    )
    (+ (mod seed template-range) u1)
  )
)

;; Create player deck
(define-public (create-deck (deck-id uint) (name (string-ascii 32)) (card-ids (list 30 uint)) (element-focus (string-ascii 16)))
  (let 
    (
      (player-collection (unwrap! (map-get? player-collections tx-sender) err-not-found))
    )
    
    (asserts! (<= (len card-ids) (var-get max-deck-size)) err-deck-full)
    (asserts! (>= (len card-ids) u20) err-invalid-deck) ;; Minimum deck size
    (asserts! (validate-deck-ownership card-ids) err-unauthorized)
    
    (map-set player-decks {player: tx-sender, deck-id: deck-id}
      {
        name: name,
        card-ids: card-ids,
        deck-size: (len card-ids),
        element-focus: element-focus,
        win-rate: u0,
        battles-played: u0,
        is-active: true
      }
    )
    
    ;; Mark cards as in deck
    (mark-cards-in-deck card-ids)
    (ok true)
  )
)

;; Validate deck ownership
(define-private (validate-deck-ownership (deck-cards (list 30 uint)))
  (fold check-card-ownership deck-cards true)
)

;; Check individual card ownership
(define-private (check-card-ownership (card-id uint) (valid bool))
  (and valid (is-card-owned-by-player card-id tx-sender))
)

;; Check if card is owned by player
(define-private (is-card-owned-by-player (card-id uint) (player principal))
  (match (map-get? cards card-id)
    card (is-eq (get owner card) player)
    false
  )
)

;; Mark cards as in deck
(define-private (mark-cards-in-deck (card-ids (list 30 uint)))
  (fold mark-single-card-in-deck card-ids true)
)

;; Mark single card in deck
(define-private (mark-single-card-in-deck (card-id uint) (success bool))
  (and success
    (match (map-get? cards card-id)
      card (begin
             (map-set cards card-id (merge card {in-deck: true}))
             true
           )
      false
    )
  )
)

;; Start battle (simplified)
(define-public (start-battle (opponent principal) (my-deck-id uint) (opponent-deck-id uint) (battle-type (string-ascii 16)))
  (let 
    (
      (battle-id (var-get next-battle-id))
      (my-deck (unwrap! (map-get? player-decks {player: tx-sender, deck-id: my-deck-id}) err-not-found))
      (opponent-deck (unwrap! (map-get? player-decks {player: opponent, deck-id: opponent-deck-id}) err-not-found))
    )
    
    (asserts! (get is-active my-deck) err-invalid-deck)
    (asserts! (get is-active opponent-deck) err-invalid-deck)
    
    ;; Create battle
    (map-set card-battles battle-id
      {
        player1: tx-sender,
        player2: opponent,
        player1-deck: my-deck-id,
        player2-deck: opponent-deck-id,
        current-turn: tx-sender,
        turn-number: u1,
        player1-health: u30,
        player2-health: u30,
        player1-energy: u1,
        player2-energy: u1,
        status: "active",
        winner: none,
        battle-type: battle-type,
        start-block: block-height
      }
    )
    
    ;; Initialize starting hands (simplified)
    (map-set battle-hands {battle-id: battle-id, player: tx-sender}
      {
        hand-cards: (list),
        hand-size: u5,
        cards-played: u0,
        energy-spent: u0
      }
    )
    
    (map-set battle-hands {battle-id: battle-id, player: opponent}
      {
        hand-cards: (list),
        hand-size: u5,
        cards-played: u0,
        energy-spent: u0
      }
    )
    
    (var-set next-battle-id (+ battle-id u1))
    (ok battle-id)
  )
)

;; Play card in battle
(define-public (play-card (battle-id uint) (card-id uint) (target-position uint))
  (let 
    (
      (battle (unwrap! (map-get? card-battles battle-id) err-not-found))
      (card (unwrap! (map-get? cards card-id) err-not-found))
      (template (unwrap! (map-get? card-templates (get template-id card)) err-not-found))
      (current-player (get current-turn battle))
      (player-energy (if (is-eq current-player (get player1 battle)) 
                       (get player1-energy battle) 
                       (get player2-energy battle)))
      (hand (unwrap! (map-get? battle-hands {battle-id: battle-id, player: current-player}) err-not-found))
    )
    
    ;; Validate play conditions
    (asserts! (is-eq tx-sender current-player) err-unauthorized)
    (asserts! (is-eq (get status battle) "active") err-invalid-battle)
    (asserts! (>= player-energy (get cost template)) err-insufficient-energy)
    (asserts! (< target-position u5) err-invalid-battle) ;; Max 5 field positions
    
    ;; Place card on battlefield
    (map-set battle-field {battle-id: battle-id, position: target-position}
      {
        card-id: card-id,
        owner: current-player,
        current-health: (get health template),
        current-attack: (get attack template),
        can-attack: false ;; Summoning sickness
      }
    )
    
    ;; Update player energy
    (let 
      (
        (new-energy (- player-energy (get cost template)))
      )
      (map-set card-battles battle-id
        (if (is-eq current-player (get player1 battle))
          (merge battle {player1-energy: new-energy})
          (merge battle {player2-energy: new-energy})
        )
      )
    )
    
    ;; Update hand
    (map-set battle-hands {battle-id: battle-id, player: current-player}
      (merge hand 
        {
          hand-size: (- (get hand-size hand) u1),
          cards-played: (+ (get cards-played hand) u1),
          energy-spent: (+ (get energy-spent hand) (get cost template))
        }
      )
    )
    
    (ok true)
  )
)

;; Attack with card
(define-public (attack-with-card (battle-id uint) (attacker-position uint) (target-position uint))
  (let 
    (
      (battle (unwrap! (map-get? card-battles battle-id) err-not-found))
      (attacker (unwrap! (map-get? battle-field {battle-id: battle-id, position: attacker-position}) err-not-found))
      (target (map-get? battle-field {battle-id: battle-id, position: target-position}))
      (current-player (get current-turn battle))
    )
    
    ;; Validate attack conditions
    (asserts! (is-eq tx-sender current-player) err-unauthorized)
    (asserts! (is-eq (get status battle) "active") err-invalid-battle)
    (asserts! (is-eq (get owner attacker) current-player) err-unauthorized)
    (asserts! (get can-attack attacker) err-invalid-battle)
    
    (if (is-some target)
      ;; Attack creature
      (let 
        (
          (target-card (unwrap-panic target))
          (damage (get current-attack attacker))
          (new-target-health (if (> (get current-health target-card) damage)
                              (- (get current-health target-card) damage)
                              u0))
        )
        ;; Apply damage
        (if (> new-target-health u0)
          ;; Target survives
          (map-set battle-field {battle-id: battle-id, position: target-position}
            (merge target-card {current-health: new-target-health})
          )
          ;; Target destroyed - remove from field
          (map-delete battle-field {battle-id: battle-id, position: target-position})
        )
        
        ;; Mark attacker as used
        (map-set battle-field {battle-id: battle-id, position: attacker-position}
          (merge attacker {can-attack: false})
        )
        
        (ok true)
      )
      ;; Attack player directly
      (let 
        (
          (opponent (if (is-eq current-player (get player1 battle)) 
                      (get player2 battle) 
                      (get player1 battle)))
          (opponent-health (if (is-eq current-player (get player1 battle)) 
                            (get player2-health battle) 
                            (get player1-health battle)))
          (damage (get current-attack attacker))
          (new-health (if (> opponent-health damage) (- opponent-health damage) u0))
        )
        
        ;; Apply damage to player
        (map-set card-battles battle-id
          (if (is-eq current-player (get player1 battle))
            (merge battle {player2-health: new-health})
            (merge battle {player1-health: new-health})
          )
        )
        
        ;; Check for game end
        (if (is-eq new-health u0)
          (end-battle battle-id current-player)
          (ok true)
        )
      )
    )
  )
)

;; End turn
(define-public (end-turn (battle-id uint))
  (let 
    (
      (battle (unwrap! (map-get? card-battles battle-id) err-not-found))
      (current-player (get current-turn battle))
      (next-player (if (is-eq current-player (get player1 battle)) 
                     (get player2 battle) 
                     (get player1 battle)))
      (next-turn-number (+ (get turn-number battle) u1))
      (next-energy (if (<= (+ (/ next-turn-number u2) u1) u10) 
                     (+ (/ next-turn-number u2) u1) 
                     u10)) ;; Energy increases each turn, max 10
    )
    
    (asserts! (is-eq tx-sender current-player) err-unauthorized)
    (asserts! (is-eq (get status battle) "active") err-invalid-battle)
    
    ;; Update battle state
    (map-set card-battles battle-id
      (merge battle 
        {
          current-turn: next-player,
          turn-number: next-turn-number,
          player1-energy: (if (is-eq next-player (get player1 battle)) next-energy (get player1-energy battle)),
          player2-energy: (if (is-eq next-player (get player2 battle)) next-energy (get player2-energy battle))
        }
      )
    )
    
    ;; Reset creature attack abilities for next player (simplified)
    (reset-field-attacks battle-id next-player)
    
    (ok true)
  )
)

;; Reset creature attack abilities (simplified)
(define-private (reset-field-attacks (battle-id uint) (player principal))
  ;; Simplified implementation - in a full version would iterate through all positions
  (begin
    (reset-position-attack battle-id player u0)
    (reset-position-attack battle-id player u1)
    (reset-position-attack battle-id player u2)
    (reset-position-attack battle-id player u3)
    (reset-position-attack battle-id player u4)
    true
  )
)

;; Reset attack for specific position
(define-private (reset-position-attack (battle-id uint) (player principal) (position uint))
  (let 
    (
      (field-card (map-get? battle-field {battle-id: battle-id, position: position}))
    )
    (if (is-some field-card)
      (let 
        (
          (card-data (unwrap-panic field-card))
        )
        (if (is-eq (get owner card-data) player)
          (map-set battle-field {battle-id: battle-id, position: position}
            (merge card-data {can-attack: true})
          )
          true
        )
      )
      true
    )
  )
)

;; End battle
(define-private (end-battle (battle-id uint) (winner principal))
  (let 
    (
      (battle (unwrap! (map-get? card-battles battle-id) err-not-found))
      (loser (if (is-eq winner (get player1 battle)) (get player2 battle) (get player1 battle)))
      (winner-stats (default-to 
                      {total-battles: u0, wins: u0, losses: u0, ranking-points: u1000, highest-rank: u0, cards-collected: u0, packs-opened: u0, tournaments-won: u0}
                      (map-get? player-stats winner)))
      (loser-stats (default-to 
                     {total-battles: u0, wins: u0, losses: u0, ranking-points: u1000, highest-rank: u0, cards-collected: u0, packs-opened: u0, tournaments-won: u0}
                     (map-get? player-stats loser)))
    )
    
    ;; Update battle status
    (map-set card-battles battle-id
      (merge battle {status: "finished", winner: (some winner)})
    )
    
    ;; Update player statistics
    (map-set player-stats winner
      (merge winner-stats 
        {
          total-battles: (+ (get total-battles winner-stats) u1),
          wins: (+ (get wins winner-stats) u1),
          ranking-points: (+ (get ranking-points winner-stats) u25)
        }
      )
    )
    
    (map-set player-stats loser
      (merge loser-stats 
        {
          total-battles: (+ (get total-battles loser-stats) u1),
          losses: (+ (get losses loser-stats) u1),
          ranking-points: (if (> (get ranking-points loser-stats) u15) 
                           (- (get ranking-points loser-stats) u15) 
                           u0)
        }
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-card-template (template-id uint))
  (map-get? card-templates template-id)
)

(define-read-only (get-card (card-id uint))
  (map-get? cards card-id)
)

(define-read-only (get-player-collection (player principal))
  (map-get? player-collections player)
)

(define-read-only (get-player-deck (player principal) (deck-id uint))
  (map-get? player-decks {player: player, deck-id: deck-id})
)

(define-read-only (get-battle (battle-id uint))
  (map-get? card-battles battle-id)
)

(define-read-only (get-battle-field (battle-id uint) (position uint))
  (map-get? battle-field {battle-id: battle-id, position: position})
)

(define-read-only (get-battle-hand (battle-id uint) (player principal))
  (map-get? battle-hands {battle-id: battle-id, player: player})
)

(define-read-only (get-player-stats (player principal))
  (map-get? player-stats player)
)

(define-read-only (get-booster-pack (pack-id uint))
  (map-get? booster-packs pack-id)
)

;; Admin functions
(define-public (set-pack-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set pack-price new-price)
    (ok true)
  )
)

(define-public (set-max-deck-size (new-size uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set max-deck-size new-size)
    (ok true)
  )
)

(define-public (emergency-end-battle (battle-id uint))
  (let 
    (
      (battle (unwrap! (map-get? card-battles battle-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set card-battles battle-id
      (merge battle {status: "finished", winner: none})
    )
    (ok true)
  )
)