module BlackJack exposing (newDeck, choose, shuffle, shuffleDeck, upHand, blackJack,
    checkAce, calcScoreHelper, calcScore, testHand, testCard, testPlayer, hit, initialMD, initialDeal, whoWon)

import Random exposing (Generator, Seed)
import Time exposing (..)
import Task exposing (..)
import Html exposing (Html, button, div, text, program)
import Html.Events exposing (onClick)
import Html exposing (..)
import Array exposing (..)
import Platform exposing (..)
import Collage exposing(..)
import Color exposing(..)
import Element exposing (..)
import Text exposing (..)



main =  Html.program {init = init
                    , view = view
                    , update = update
                    , subscriptions = subscriptions}

subscriptions model = Time.every 7000 (always Tick)


type Msg = Hit | Pass | NewGame | DoNothing | GameOver | Tick | GotTime Time
type Win = DealerWin | PlayerWin | Push 
type Turn = PlayerTurn | DealerTurn 

type alias TypeCard = Int -- 1 = Ace, 2 = 2, ..., 11 = J, 12 = Q, 13 = K
type alias SuitCard = Int -- 1 = Diamonds, 2 = Hearts, 3 = Clubs, 4 = Spades
type alias Card = {tcard: Int, scard: Int}

--Tests

testPlayer : Player
testPlayer = Player testHand (calcScore testHand) True

testHand : Hand 
testHand = [(Card 10 0), (Card 5 1)]

testCard : Card
testCard = Card 7 2

--Hand Types
type alias Hand = List Card
type alias Deck = List Card 
type alias Dealer = 
    { hand   : List Card 
    , score  : Int 
    , limit  : Int
    , alive  : Bool }
type alias Player = 
    { hand   : List Card 
    , score  : Int 
    , alive  : Bool }


type alias Model = {  deck   : List Card
                    , dealer : Dealer
                    , player : Player
                    , turn   : Turn
                    , win    : Win
                    , seed   : Seed     } 



--view/controller (update)

view : Model -> Html Msg
view model =
    let
        hitButton =
            if (model.turn == PlayerTurn) && ((List.isEmpty model.player.hand) == False) &&
                (model.player.alive == True)  || 
                (model.turn == DealerTurn && model.dealer.score < model.dealer.limit) then
                button [ onClick Hit ] [ Html.text "Hit" ]
            else if (model.turn == DealerTurn && model.dealer.score > model.dealer.limit) then
                button [ onClick DoNothing] [Html.text "Hit"]
            else button [ onClick DoNothing ] [Html.text "Hit" ]

        standButton =
            if model.turn == PlayerTurn && model.player.alive == True then
                button [onClick Pass] [Html.text "Pass"]
            else
                button [onClick DoNothing] [Html.text "Pass"]
        newGame = 
            button [onClick NewGame ] [Html.text "New Game"]
        over = 
            if ((model.turn == DealerTurn) && (model.dealer.score >= model.dealer.limit)) ||
               ((model.turn == PlayerTurn) && (model.player.alive == False)) ||
                (model.turn == DealerTurn) && ((blackJack model.player.hand) == True)
            then 
                if (model.dealer.alive == False) && (model.player.alive == True) ||
                   (model.dealer.score < model.player.score) && (model.player.alive == True) ||
                   (model.turn == DealerTurn) && ((blackJack model.player.hand) == True) &&
                   ((blackJack model.dealer.hand) == False) 
                    then Element.toHtml (leftAligned (Text.height 40 (bold (fromString "Game over, player wins"))))
                else if (model.player.alive == False) || 
                        ((model.player.score < model.dealer.score) && (model.dealer.alive == True)) ||
                        (model.turn == DealerTurn) && ((blackJack model.dealer.hand) == True) && 
                        ((blackJack model.player.hand) == False) 
                    then Element.toHtml (leftAligned (Text.height 40 (bold (fromString ("Game over, dealer wins")))))
                else
                    Element.toHtml (leftAligned (Text.height 40 (bold (fromString ("Game over, push - tie game")))))
            else br [] []
        break = br [] []
        dealercommence = 
            if (model.turn == DealerTurn) && (model.dealer.score < model.dealer.limit) && 
                ((blackJack model.player.hand) == False) ||
               (model.turn == DealerTurn) && (model.dealer.score == model.dealer.limit) &&
               ((List.length model.dealer.hand) == 2) && ((checkAce model.dealer.hand) == True) 
               && ((blackJack model.player.hand) == False)
               then Element.toHtml (leftAligned (fromString "Dealer turn playing..."))
            else Element.toHtml Element.empty
        playHand = 
            if model.player.hand == [] then Element.empty
            else leftAligned (Text.color Color.white (fromString "Player Hand: "))
        dealHand = 
            if model.dealer.hand == [] then Element.empty
            else leftAligned (Text.color Color.white (fromString "Dealer Hand: "))
    in
        div []
            [ hitButton
            , standButton
            , newGame, break
            , dealercommence, over,
              Element.toHtml (Element.layers [
                (fittedImage 1136 640 "Table/table.png"),
                (Element.above 
                    (Element.above 
                        (Element.above (Element.spacer 100 40)
                                      (Element.above dealHand
                                                     (dealerHand model)))
                        (Element.spacer 100 40))
                    (Element.above playHand
                            (cardImgs model.player.hand)))])
            ]




gameOver : Model -> Model
gameOver mdl = 
                --Case where both have Blackjack
                if (blackJack mdl.player.hand) && (blackJack mdl.dealer.hand)
                    then Model mdl.deck mdl.dealer mdl.player mdl.turn Push mdl.seed 
                --Case where only player has Blackjack
                else if (blackJack mdl.player.hand) && ((blackJack mdl.dealer.hand) == False)
                    then Model mdl.deck mdl.dealer mdl.player mdl.turn PlayerWin mdl.seed 
                --Case where player has higher score than dealer and player + dealer are still alive    
                else if (mdl.player.score > mdl.dealer.score) && (mdl.player.alive == True) && (mdl.dealer.alive == True)
                    then Model mdl.deck mdl.dealer mdl.player mdl.turn PlayerWin mdl.seed 
                --Case where dealer busts and player does not bust    
                else if (mdl.dealer.alive == False) && (mdl.player.alive == True)
                    then Model mdl.deck mdl.dealer mdl.player mdl.turn PlayerWin mdl.seed
                --Case where dealer and player have same score
                else if (mdl.dealer.score == mdl.player.score) && (mdl.player.alive == True)
                    then Model mdl.deck mdl.dealer mdl.player mdl.turn Push mdl.seed  
                --All other
                else Model mdl.deck mdl.dealer mdl.player mdl.turn DealerWin mdl.seed 



init : (Model, Cmd Msg)
init = (initialMD, Task.perform GotTime Time.now)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    let playerturn = 0 
        dealerturn = 1
    in  
        case msg of 
            DoNothing ->
                (model , Cmd.none)
            Hit -> 
                if model.turn == PlayerTurn 
                    then (hit PlayerTurn model, Cmd.none)
                else (model, Cmd.none)
            Pass ->
                (stay model, Cmd.none)
            NewGame ->
                (newGame model, Cmd.none)
            Tick -> 
                if (model.turn == DealerTurn) && (model.dealer.score < model.dealer.limit) && (model.dealer.alive == True)
                 && ((blackJack model.player.hand) == False) ||
                   (model.turn == DealerTurn) && (model.dealer.score == model.dealer.limit) && 
                    ((checkAce model.dealer.hand) == True) && ((List.length model.dealer.hand) == 2) 
                    then ((hit DealerTurn model), Cmd.none)
{--                else if (model.dealer.alive == False) || 
                    (model.turn == DealerTurn) && (model.dealer.score > model.dealer.limit) ||
                    (model.turn == PlayerTurn) && (model.player.alive == False) ||
                    (model.turn == DealerTurn) && (model.dealer.score == model.dealer.limit) &&
                    ((checkAce model.dealer.hand) == False) && ((List.length model.dealer.hand) == 2) ||
                    (model.turn == DealerTurn) && (model.dealer.score == model.dealer.limit) &&
                    ((List.length model.dealer.hand) > 2)
                    then (newGame model, Cmd.none) --}
                else 
                    (model, Cmd.none)
            GameOver ->
                (whoWon model, Cmd.none)
            GotTime fl ->
               ({ model | seed = Random.initialSeed (round fl) }, Cmd.none)



--Deck Components

shuffleDeck : Seed -> Generator (Array a) -> Array a 
shuffleDeck sd dck = 
    let (a, b) = Random.step dck sd
    in  a

updateSeed : Seed -> Generator (Array a) -> Seed
updateSeed sd dck = 
    let (a, b) = Random.step dck sd 
    in b


newDeck : Deck
newDeck = 
    let suitType : Int -> List Card 
        suitType suit = List.map (\tp -> Card tp suit) (List.range 1 13)
    in 
            List.concatMap suitType [1, 2, 3, 4]

constant : a -> Generator a
constant value =
  Random.map (\_ -> value) Random.bool


choose : Array a -> Generator (Maybe a, Array a)
choose arr = if Array.isEmpty arr then constant (Nothing, arr) else
  let lastIndex = (Array.length arr - 1)
      front i   = (Array.slice 0 i arr)
      back i    = if (i == lastIndex) -- workaround for #1
               then Array.empty
               else Array.slice (i+1) (lastIndex+1) arr
      gen = Random.int 0 lastIndex
    in Random.map (\index ->
        (Array.get index arr, Array.append (front index) (back index)))
        gen


--https://groups.google.com/forum/#!topic/elm-discuss/JYxRYfUevzc-- 
--Idea behind the Fisher-Yates shuffle algorithm
shuffle : List a -> Generator (Array a)
shuffle lst = 
    let arr = (Array.fromList lst) 
    in 
        if Array.isEmpty arr then constant arr else
        let --helper : (List a, Array a) -> Generator (List a, Array a)
            helper (done, remaining) =
            Random.andThen (\(m_val, shorter) ->
            case m_val of
                Nothing -> constant (done, shorter)
                Just val -> helper (val::done, shorter)) (choose remaining)
        in Random.map (Tuple.first>>Array.fromList) (helper ([], arr))


--Game Components
playerBust : Model -> Model
playerBust mdl = 
        if (bust mdl.player.hand) then 
            Model mdl.deck mdl.dealer mdl.player DealerTurn mdl.win mdl.seed
        else 
            Model mdl.deck mdl.dealer mdl.player PlayerTurn mdl.win mdl.seed


blackJack : Hand -> Bool
blackJack hand = 
    if ((&&) (List.length hand == 2) ((calcScore hand) == 21)) then 
        True
    else False 


newGame : Model -> Model
newGame mdl = 
    let 
        newSeed = updateSeed mdl.seed (shuffle newDeck)
        newd    = Array.toList (shuffleDeck newSeed  (shuffle newDeck))
    in 
        initialDeal (Model newd  (Dealer [] 0 17 True) (Player [] 0 True) PlayerTurn Push newSeed)


bust : Hand -> Bool
bust hand = 
    if ((calcScore hand) > 21) then 
        True
    else False 


calcScoreHelper : Hand -> Int
calcScoreHelper hnd = 
    case hnd of
        [] -> 0
        x::xs -> 
            --If 10, J, Q, K
            if (x.tcard >= 10) then 
                10 + (calcScoreHelper xs)
            --If regular other cards
            else (x.tcard) + (calcScoreHelper xs)

checkAce : Hand -> Bool
checkAce hnd = 
    case hnd of 
        [] -> False 
        x::xs -> 
            if (x.tcard == 1) 
                then True 
            else checkAce xs



calcScore : Hand -> Int 
calcScore hnd = 
    if (checkAce hnd) then 
        if (calcScoreHelper hnd) + 10 <= 21 
            then (calcScoreHelper hnd) + 10 
        else (calcScoreHelper hnd)
    else calcScoreHelper hnd 


upHand : Card -> Player -> Player 
upHand crd ply = 
    let newHand = crd::ply.hand
        newScore = calcScore newHand
    in  
        if (calcScore newHand) > 21 then 
            --Player busted with over 21
            Player newHand newScore False
        else 
            --Player is still alive!
            Player newHand newScore True



upDealer : Card -> Dealer -> Dealer
upDealer crd deal = 
    let newHand = crd::deal.hand 
        newScore = calcScore newHand
    in 
        if (calcScore newHand) > 21 then
            Dealer newHand newScore 17 False
        else 
            Dealer newHand newScore 17 True



hit : Turn -> Model -> Model
hit i mdl = 
    let updeck = Array.toList (Array.slice 1 (Array.length (Array.fromList mdl.deck)) (Array.fromList mdl.deck))
        fstcrd = Maybe.withDefault (Card 0 0) (Array.get 0 (Array.fromList mdl.deck))
    in 
        if (i == PlayerTurn) then
            Model updeck mdl.dealer (upHand fstcrd mdl.player) mdl.turn mdl.win mdl.seed
        else 
            Model updeck (upDealer fstcrd mdl.dealer) mdl.player mdl.turn mdl.win mdl.seed


--Assume player stays, so turn is updated to dealer
stay : Model -> Model
stay mdl = 
    if (mdl.turn == PlayerTurn) then 
        Model mdl.deck mdl.dealer mdl.player DealerTurn mdl.win mdl.seed  
    else (whoWon mdl)


--Cases: 
    --Player score > Dealer score, under 22.
    --Player score == Dealer score, under 22
    --Player score < Dealer score OR bust 
whoWon : Model -> Model
whoWon mdl = 
    if (mdl.player.score > mdl.dealer.score) && (mdl.player.score <= 21)
        then (Model mdl.deck mdl.dealer mdl.player mdl.turn PlayerWin mdl.seed)
    else if (mdl.player.score == mdl.dealer.score) && (mdl.player.score <= 21) 
        then (Model mdl.deck mdl.dealer mdl.player mdl.turn Push mdl.seed)
    --Redundant case for last 2 (cases #3,4) but put in to emphasize all cases... 
    --Very negligible time to check...
    else if (bust mdl.player.hand)
        then (Model mdl.deck mdl.dealer mdl.player DealerTurn DealerWin mdl.seed)
    else (Model mdl.deck mdl.dealer mdl.player mdl.turn DealerWin mdl.seed)


--Game Functions

initialMD : Model 
initialMD = 
    let initialModel : Model
        initialModel = 
            Model [] (Dealer [] 0 17 True) (Player [] 0 True) PlayerTurn Push (Random.initialSeed 289423)
    in 
        Model (Array.toList (shuffleDeck initialModel.seed (shuffle newDeck)))
                    initialModel.dealer 
                    initialModel.player 
                    initialModel.turn 
                    initialModel.win 
                    (updateSeed initialModel.seed (shuffle newDeck))


initialDeal : Model -> Model
initialDeal mdl = hit DealerTurn (hit PlayerTurn (hit DealerTurn (hit PlayerTurn mdl)))

makeCard : Int -> Int -> Card
makeCard t s = Card t s


--View components

cardImg : Card -> Element
cardImg c = 
    if c.scard == 4 then
        image 195 220 ("Cards/" ++ (toString c.tcard) ++ "_of_spades.png")
    else if c.scard == 3 then 
        image 195 220 ("Cards/" ++ (toString c.tcard) ++ "_of_hearts.png")
    else if c.scard == 2 then 
        image 195 220 ("Cards/" ++ (toString c.tcard) ++ "_of_diamonds.png")
    else if c.scard == 1 then 
        image 195 220 ("Cards/" ++ (toString c.tcard) ++ "_of_clubs.png")
    else 
        show "Bogus case"


cardImgs : List Card -> Element
cardImgs lc = 
    case lc of 
        [] -> Element.empty
        x::xs -> flow right ((cardImg x)::[(cardImgs xs)])

dealerHand : Model -> Element
dealerHand mdl = 
    let dh = mdl.dealer.hand 
        first = Maybe.withDefault (Card 0 0) (List.head dh)
    in 
        if (mdl.turn == PlayerTurn) && ((List.length mdl.dealer.hand) == 2)
                then flow right [(cardImg first), (image 195 220 ("Cards/back_card.jpg"))]
        else (cardImgs dh)
