#import <Foundation/Foundation.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "ChessMoves.h"

#define BOARD_SIZE 8
#define DEBUG_MODE 0

void debugMessage(char *message) {
    if (DEBUG_MODE == 1) {
        printf("%s\n", message);
        fflush(stdout);
    }
}

char **playTheGame(Game *g) {
    int i;
    
    char **board = createChessBoard();
    Move whiteMove;
    Move blackMove;
    printChessBoard(board);
    
    for (i = 0; i < g->numMoves; i++) {
        parseNotationString(g->moves[i], &whiteMove, &blackMove);
        movePiece(board, &whiteMove);
        printChessBoard(board);
        
        // Prevents movePiece() from running when the game ends in with White's move
        if (blackMove.isCapture != -1) {
            movePiece(board, &blackMove);
            printChessBoard(board);
        }
    }
    
    return board;
}

char **createChessBoard(void) {
    int i;
    int row, col;
    char **board = malloc(sizeof(char *) * BOARD_SIZE);
    
    if (board == NULL) {
        return NULL;
    }
    
    for (i = 0; i < BOARD_SIZE; i++) {
        board[i] = malloc(sizeof(char) * BOARD_SIZE);
    }
    
    if (board == NULL) {
        return NULL;
    }
    
    for (row = 0; row < BOARD_SIZE; row++) {
        for (col = 0; col < BOARD_SIZE; col++) {
            if (row == 0 || row == 7) {
                if (col == 0 || col == 7) {
                    board[row][col] = (row == 0 ? 'R' : 'r'); // rook
                } else if (col == 1 || col == 6) {
                    board[row][col] = (row == 0 ? 'N' : 'n'); // knight
                } else if (col == 2 || col == 5) {
                    board[row][col] = (row == 0 ? 'B' : 'b'); // bishop
                } else if (col == 3) {
                    board[row][col] = (row == 0 ? 'Q' : 'q'); // queen
                } else if (col == 4) {
                    board[row][col] = (row == 0 ? 'K' : 'k'); // king
                }
            } else if (row == 1 || row == 6) {
                board[row][col] = (row == 1 ? 'P' : 'p');     // pawn
            } else {
                board[row][col] = ' ';                        // blank
            }
        }
    }
    
    return board;
}

void printChessBoard(char **board) {
    int i;
    int row, col;
    
    for (i = 0; i < BOARD_SIZE; i++) {
        printf("=");
        if (i == (BOARD_SIZE - 1)) {
            printf("\n");
        }
    }
    
    for (row = 0; row < BOARD_SIZE; row++) {
        for (col = 0; col < BOARD_SIZE; col++) {
            printf("%c", board[row][col]);
        }
        
        printf("\n");
    }
    
    for (i = 0; i < BOARD_SIZE; i++) {
        printf("=");
        if (i == (BOARD_SIZE - 1)) {
            printf("\n\n");
        }
    }
    
    return;
}

void parseNotationString(char *str, Move *whiteMove, Move *blackMove) {
    char whiteMoveString[10], blackMoveString[10], endGameString[10];
    int whiteStrLen = 0;
    int blackStrLen = 0;
    int setBlackMoveString = 1;
    
    // Ignores the first found string (which will be the move number)
    // Then sets the following strings until one isn't found
    // These strings are found via terminating with white space
    sscanf(str, "%*s%s%s%s", whiteMoveString, blackMoveString, endGameString);
    
    // Detects if the second string is actually the endGameString
    // Sets isCapture to -1 to be checked by playTheGame()
    // This will prevent the following if (setBlackMoveString) statements from running
    if ((blackMoveString[0] == '1') || (blackMoveString[0] == '0')) {
        strcpy(endGameString, blackMoveString);
        blackMove->isCapture = -1;
        setBlackMoveString = 0;
    }
    
    // Defaults isCapture for later
    // Needed because of my manipulation of isCapture for bonus cases
    whiteMove->isCapture = 0;
    if (setBlackMoveString) blackMove->isCapture = 0;
    
    checkForOmittedP(whiteMoveString);
    if (setBlackMoveString) checkForOmittedP(blackMoveString);
    
    setMoveColor(whiteMove, WHITE);
    if (setBlackMoveString) setMoveColor(blackMove, BLACK);
    
    whiteStrLen = (int) strlen(whiteMoveString);
    if (setBlackMoveString) blackStrLen = (int) strlen(blackMoveString);
    
    checkEnPassant(whiteMoveString, &whiteStrLen, whiteMove);
    if (setBlackMoveString) checkEnPassant(blackMoveString, &blackStrLen, blackMove);
    
    checkPawnPromotion(whiteMoveString, &whiteStrLen, whiteMove);
    if (setBlackMoveString) checkPawnPromotion(blackMoveString, &blackStrLen, blackMove);
    
    if (checkForCastling(whiteMoveString, whiteMove) == 1) {
        // Does nothing if castling is detected for White
    } else if (checkForCastling(blackMoveString, blackMove) == 1) {
        // Does nothing if castling is detected for Black
    } else {
        checkIsCapture(whiteMoveString, whiteMove);
        
        if (setBlackMoveString) {
            checkIsCapture(blackMoveString, blackMove);
        }
        
        checkLoc(whiteMoveString, whiteMove, whiteStrLen);
        
        if (setBlackMoveString) {
            checkLoc(blackMoveString, blackMove, blackStrLen);
        }
    }
}

void checkForOmittedP(char *str) {
    // Adds a 'P' to the beginning of strings that omit the 'P'
    // Makes my life so much easier later
    
    char strChar, strTemp[10];
    
    sscanf(str, "%c", &strChar);
    
    if (strChar == 'x' || strChar >= 'a') {
        strcpy(strTemp, "P");
        strcat(strTemp, str);
        strcpy(str, strTemp);
    }
}

void setMoveColor(Move *move, Color color) {
    move->color = color;
}

void checkEnPassant(char *moveString, int *strLen, Move *move) {
    // Checks for en passant by looking for a '.' at the end of the string
    // Then manipulates isCapture for later
    // Then fixes the string by removing 'e.p.'
    
    if (moveString[*strLen-1] == '.') {
        move->isCapture = 2;
        moveString[*strLen-4] = '\0';
        *strLen -= 4;
    }
}

void checkPawnPromotion(char *moveString, int *strLen, Move *move) {
    // Checks for pawn promotion by seeing if the last char in a string is a piece
    // Manipulates isCapture for later
    
    switch (moveString[*strLen-1]) {
        case 'Q':
            move->isCapture = -3;
            break;
        case 'B':
            move->isCapture = -4;
            break;
        case 'R':
            move->isCapture = -5;
            break;
        case 'N':
            move->isCapture = -6;
            break;
        default :
            // No pawn promotion detected
            break;
    }
    
    // Fixes the string for later
    if (move->isCapture <= -3) {
        moveString[*strLen-1] = '\0';
        *strLen -= 1;
    }
}

int checkForCastling(char *str, Move *move) {
    // Checks for castling by seeing if the string starts with 'O'
    // Manipulates isCapture for later
    
    int castlingHappened = 0;
    
    if (strcmp(str, "O-O") == 0) {
        move->isCapture = -2;
        castlingHappened = 1;
    } else if (strcmp(str, "O-O-O") == 0) {
        move->isCapture = -3;
        castlingHappened = 1;
    }
    
    return castlingHappened;
}

void checkIsCapture(char *str, Move *move) {
    int i;
    
    // Returns away from this function if en passant is detected
    // En passant is always a capture move, so it doesn't need to be changed
    if (move->isCapture == 2) {
        return;
    }
    
    for (i = 0; str[i] != '\0'; i++) {
        if (str[i] == 'x') {
            // If pawn promotion is detected, this will change the value to positive
            if (move->isCapture <= -3) {
                move->isCapture *= -1;
            } else {
                move->isCapture = 1;
            }
            return;
        }
    }
    
    if (move->isCapture <= -3) {
        // This preserves pawn promotion with no capture
    } else {
        move->isCapture = 0;
    }
}

void checkLoc(char *str, Move *move, int strLen) {
    if ((strLen - move->isCapture) == 5) {
        move->from_loc.col = str[1];
        move->from_loc.row = str[2] - '0';
    } else if ((strLen - move->isCapture) == 4) {
        if (str[1] >= 'a') {
            move->from_loc.col = str[1];
            move->from_loc.row = -1;
        } else {
            move->from_loc.col = 'x';
            move->from_loc.row = str[1] - '0';
        }
    } else {
        move->from_loc.col = 'x';
        move->from_loc.row = -1;
    }
    
    move->to_loc.col = str[strLen - 2];
    move->to_loc.row = str[strLen - 1] - '0';
    move->piece = str[0];
}

void movePiece(char **board, Move *move) {
    int toRow = convertRow(move->to_loc.row);
    int toCol = convertCol(move->to_loc.col);
    
    int fromRow;
    int fromCol;
    
    // Checks for castling
    if (move->isCapture == -2 || move->isCapture == -3) {
        moveForCastling(board, move);
        return;
    }
    
    findFromLoc(board, move);
    
    fromRow = convertRow(move->from_loc.row);
    fromCol = convertCol(move->from_loc.col);
    
    board[fromRow][fromCol] = ' ';
    
    // Checks for pawn promotion
    switch (move->isCapture) {
        case 3:
        case -3:
            board[toRow][toCol] = (move->color == WHITE) ? 'q' : 'Q';
            break;
        case 4:
        case -4:
            board[toRow][toCol] = (move->color == WHITE) ? 'b' : 'B';
            break;
        case 5:
        case -5:
            board[toRow][toCol] = (move->color == WHITE) ? 'r' : 'R';
            break;
        case 6:
        case -6:
            board[toRow][toCol] = (move->color == WHITE) ? 'n' : 'N';
            break;
        default:
            board[toRow][toCol] = (move->color == BLACK) ? move->piece : tolower(move->piece);
            break;
    }
    
    // Checks for en passant
    if (move->isCapture == 2) {
        if (move->color == WHITE) {
            board[toRow+1][toCol] = ' ';
        } else if (move->color == BLACK) {
            board[toRow-1][toCol] = ' ';
        }
    }
}

int convertRow(int row) {
    if (row == -1) {
        return -1;
    } else {
        return (8 - row);
    }
}

int convertCol(char col) {
    if (col == 'x') {
        return -1;
    } else {
        return (col - 'a');
    }
}

void moveForCastling(char **board, Move *move) {
    int row = (move->color == WHITE) ? (7) : (0);
    char side = (move->isCapture == -2) ? ('K') : ('Q'); //kindside vs queenside
    
    board[row][4] = ' ';
    
    if (side == 'K') {
        board[row][7] = ' ';
        board[row][6] = (move->color == WHITE) ? ('k') : ('K');
        board[row][5] = (move->color == WHITE) ? ('r') : ('R');
    } else if (side == 'Q') {
        board[row][0] = ' ';
        board[row][2] = (move->color == WHITE) ? ('k') : ('K');
        board[row][3] = (move->color == WHITE) ? ('r') : ('R');
    }
}

void findFromLoc(char **board, Move *move) {
    if (move->from_loc.col != 'x' && move->from_loc.row != -1) {
        return;
    }
    
    // All of the following function use dark magic in order to work
    switch (move->piece) {
        case 'R':
            findFromLocR(board, move);
            break;
        case 'N':
            findFromLocN(board, move);
            break;
        case 'B':
            findFromLocB(board, move);
            break;
        case 'Q':
            findFromLocQ(board, move);
            break;
        case 'K':
            findFromLocK(board, move);
            break;
        default : // 'P'
            findFromLocP(board, move);
            break;
    }
}

void findFromLocR(char **board, Move *move) {
    int toRow = convertRow(move->to_loc.row);
    int toCol = convertCol(move->to_loc.col);
    int fromRow = convertRow(move->from_loc.row);
    int fromCol = convertCol(move->from_loc.col);
    
    int i;
    
    char find = (move->color == BLACK) ? (move->piece) : tolower(move->piece);
    
    for (i = 1; (toCol+i) <= 7; i++) {
        if (board[toRow][toCol+i] == find) {
            if (move->from_loc.col != 'x' && toCol+i != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row;
            move->from_loc.col = move->to_loc.col + i;
            return;
        } else if (board[toRow][toCol+i] != ' ') {
            break;
        }
    }
    
    for (i = 1; (toCol-i) >= 0; i++) {
        if (board[toRow][toCol-i] == find) {
            if (move->from_loc.col != 'x' && toCol-i != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row;
            move->from_loc.col = move->to_loc.col - i;
            return;
        } else if (board[toRow][toCol-i] != ' ') {
            break;
        }
    }
    
    for (i = 1; (toRow-i) >= 0; i++) {
        if (board[toRow-i][toCol] == find) {
            
            if (move->from_loc.col != 'x' && toCol != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow-i != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row + i;
            move->from_loc.col = move->to_loc.col;
            return;
        } else if (board[toRow-i][toCol] != ' ') {
            break;
        }
    }
    
    for (i = 1; (toRow+i) <= 7; i++) {
        if (board[toRow+i][toCol] == find) {
            if (move->from_loc.col != 'x' && toCol != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow+i != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row - i;
            move->from_loc.col = move->to_loc.col;
            return;
        } else if (board[toRow+i][toCol] != ' ') {
            break;
        }
    }
}

void findFromLocN(char **board, Move *move) {
    int toRow = convertRow(move->to_loc.row);
    int toCol = convertCol(move->to_loc.col);
    int fromRow = convertRow(move->from_loc.row);
    int fromCol = convertCol(move->from_loc.col);
    
    int i, j;
    
    char find = (move->color == BLACK) ? (move->piece) : tolower(move->piece);
    
    for (i = -2; i <= 2; i++) {
        for (j = -2; j <= 2; j++) {
            if (i == 0 || j == 0) {
                // do nothing
            } else if (abs(i) == abs(j)) {
                // do nothing
            } else {
                if (toRow + i > 7 || toRow + i < 0) {
                    // do nothing
                } else if (toCol + j > 7 || toCol + j < 0) {
                    // do nothing
                } else if (board[toRow + i][toCol + j] == find){
                    if (move->from_loc.col != 'x' && toCol+j != fromCol) {
                        break;
                    }
                    
                    if (move->from_loc.row != -1 && toRow-i != fromRow) {
                        break;
                    }
                    
                    move->from_loc.row = move->to_loc.row - i;
                    move->from_loc.col = move->to_loc.col + j;
                }
            }
        }
    }
}

void findFromLocB(char **board, Move *move) {
    int toRow = convertRow(move->to_loc.row);
    int toCol = convertCol(move->to_loc.col);
    int fromRow = convertRow(move->from_loc.row);
    int fromCol = convertCol(move->from_loc.col);
    
    int i;
    
    char find = (move->color == BLACK) ? (move->piece) : tolower(move->piece);
    
    for (i = 1; (toRow+i) <= 7 &&  (toCol+i) <= 7; i++) {
        if (board[toRow+i][toCol+i] == find) {
            if (move->from_loc.col != 'x' && toCol+i != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow-i != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row - i;
            move->from_loc.col = move->to_loc.col + i;
            return;
        } else if (board[toRow+i][toCol+i] != ' ') {
            break;
        }
    }
    
    for (i = 1; (toRow-i) >= 0 &&  (toCol-i) >= 0; i++) {
        if (board[toRow-i][toCol-i] == find) {
            if (move->from_loc.col != 'x' && toCol-i != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow+i != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row + i;
            move->from_loc.col = move->to_loc.col - i;
            return;
        } else if (board[toRow-i][toCol-i] != ' ') {
            break;
        }
    }
    
    for (i = 1; (toRow+i) <= 7 &&  (toCol-i) >= 0; i++) {
        if (board[toRow+i][toCol-i] == find) {
            if (move->from_loc.col != 'x' && toCol-i != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow-i != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row - i;
            move->from_loc.col = move->to_loc.col - i;
            return;
        } else if (board[toRow+i][toCol-i] != ' ') {
            break;
        }
    }
    
    for (i = 1; (toRow-i) >= 0 &&  (toCol+i) <= 7; i++) {
        if (board[toRow-i][toCol+i] == find) {
            if (move->from_loc.col != 'x' && toCol+i != fromCol) {
                break;
            }
            
            if (move->from_loc.row != -1 && toRow+i != fromRow) {
                break;
            }
            
            move->from_loc.row = move->to_loc.row + i;
            move->from_loc.col = move->to_loc.col + i;
            return;
        } else if (board[toRow-i][toCol+i] != ' ') {
            break;
        }
    }
}

void findFromLocQ(char **board, Move *move) {
    // #lazylife
    findFromLocB(board, move);
    findFromLocR(board, move);
}

void findFromLocK(char **board, Move *move) {
    int toRow = convertRow(move->to_loc.row);
    int toCol = convertCol(move->to_loc.col);
    
    int i, j;
    
    char find = (move->color == BLACK) ? (move->piece) : tolower(move->piece);
    
    for (i = -1; i <= 1; i++) {
        for (j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) {
                continue;
            } else if (toRow-i < 0 || toRow-i > 7) {
                continue;
            } else if (toCol+j < 0 || toCol+j > 7) {
                continue;
            } else if (board[toRow-i][toCol+j] == find) {
                move->from_loc.row = move->to_loc.row + i;
                move->from_loc.col = move->to_loc.col + j;
                return;
            } else if (board[toRow-i][toCol+j] != ' ') {
                continue;
            }
        }
    }
}

void findFromLocP(char **board, Move *move) {
    int toRow = convertRow(move->to_loc.row);
    int toCol = convertCol(move->to_loc.col);
    int fromCol;
    
    char find = (move->color == BLACK) ? (move->piece) : tolower(move->piece);
    
    if (move->from_loc.col == 'x') {
        if (move->isCapture > 0 && move->color == BLACK) {
            if (board[toRow-1][toCol+1] == find) {
                move->from_loc.col = move->to_loc.col + 1;
            } else {
                move->from_loc.col = move->to_loc.col - 1;
            }
        } else if (move->isCapture > 0 && move->color == WHITE) {
            if (board[toRow+1][toCol+1] == find) {
                move->from_loc.col = move->to_loc.col + 1;
            } else {
                move->from_loc.col = move->to_loc.col - 1;
            }
        } else {
            move->from_loc.col = move->to_loc.col;
        }
    }
    
    fromCol = convertCol(move->from_loc.col);
    
    if (move->from_loc.row == -1) {
        if (move->color == WHITE) {
            if (board[toRow+1][fromCol] == find) {
                move->from_loc.row = move->to_loc.row - 1;
            } else {
                move->from_loc.row = move->to_loc.row - 2;
            }
        } else {
            if (board[toRow-1][fromCol] == find) {
                move->from_loc.row = move->to_loc.row + 1;
            } else {
                move->from_loc.row = move->to_loc.row + 2;
            }
        }
    }
}

char **destroyChessBoard(char **board) {
    int i;
    
    for (i = 0; i < BOARD_SIZE; i++) {
        free(board[i]);
    }
    
    free(board);
    
    board = NULL;
    
    return board;
}
