Playing instructions - 

Compile the BlackJack.elm file with all the other files included in the “part3” folder.

-> “elm-make BlackJack.elm” 

and it will output an “index.html” file.

Simply run the “index.html” file with your browser of choice.

The initial model will simply show a poker table with the texts “Player Hand” and “Dealer Hand” labeled with three buttons - “Hit” “Stay” and “New Game” up top.
Initiate a new game by hitting the “New Game” button.

Game Play:

The rules of the game are as follows:

General objective - In order for the player to win, he must have a higher hand than the dealer, and he must not bust (“hit” over 21). 

Initial Deal - both the dealer and the player are given two cards; however the player can only see one of the dealer’s cards. The player starts his turn.

Player Turn - the player can choose to “hit” or “pass”/“stay”. If the player chooses to “hit”, he will receive another card, in which he adds to his sum total. If he busts, then the game is over - the player loses. If he chooses to stay and has not busted, then it is now the dealer’s turn. If the player hits a blackjack (21 with 2 cards), then if the dealer also hits a blackjack, the two “push” or tie; however, if the player hits a blackjack and the dealer does not initially have a blackjack, then the player wins.

Dealer Turn - the dealer first reveals his card to the player when the player passes. If the dealer has a 17 or above, then he must stop; however if the dealer’s 17 is a “soft” 17, where he deals an “Ace” that can be treated as a 1 or 11, he must hit again. If the dealer is below 17 or has a soft 17, he must continue hitting until he he hits at least a 17 that is not soft. If the dealer hits above 21, then he busts.

If both players have not busted or either have not gotten a Blackjack by the time the dealer passes, then the two hands are compared. The higher hand wins the round, and if the hand values are the same, then the dealer and the player “push”/tie.

The values of the cards for counting are as follows:

A - 1 or 11 (Initially treated as 11 and then treated as a 1 after)
2 - 2
3 - 3
.
.
.
9 - 9
10 - 10
J - 10
Q - 10
K - 10 

Button functions (for player):

“Hit” - Will hit on a player’s turn; however it will not hit on the dealer’s turn
“Pass” - Will pass on a player’s turn’ however it will not pass on the dealer’s turn
“New game” - Will start a new game

Dealer automation:

Dealer will automatically hit or pass! You do not need to control/play for the dealer.


