#import <Foundation/Foundation.h>

#ifndef __CHESSMOVES_H
#define __CHESSMOVES_H

typedef enum {
    BLACK,
    WHITE
} Color;

typedef struct Game {
    // array of algebraic chess notation strings
    char **moves;
    
    // number of strings in the 'movse' array
    int numMoves;
} Game;

typedef struct Location {
    // the square's column ('a' through 'h')
    char col;
    
    // the square's row (1 through 8)
    int row;
} Location;

typedef struct Move {
    // location where this piece is moving from
    Location from_loc;
    
    // location where this piece is moving to
    Location to_loc;
    
    // what type of chess piece is being moved
    char piece;
    
    // whether this move captures another piece
    short int isCapture;
    
    // the color of the piece being moved
    Color color;
} Move;

// Functional Prototypes (assignment)

char **createChessBoard(void);

char **destroyChessBoard(char **board);

void printChessBoard(char **board);

char **playTheGame(Game *g);

void parseNotationString(char *str, Move *whiteMove, Move *blackMove);

void movePiece(char **board, Move *move);

void findFromLoc(char **board, Move *move);

// end Functional Prototypes (assignment)

// Functional Prototypes (additional)

void debugMessage(char *message);

// The following are called from parseNotationString()

void checkForOmittedP(char *str);

void setMoveColor(Move *move, Color color);

void checkEnPassant(char *moveString, int *strLen, Move *move);

void checkPawnPromotion(char *moveString, int *strLen, Move *move);

int checkForCastling(char *str, Move *move);

void checkIsCapture(char *str, Move *move);

void checkLoc(char *str, Move *move, int strLen);

// The following are called from movePiece()

int convertRow(int row);

int convertCol(char col);

void moveForCastling(char **board, Move *move);

// The following are called from findFromLoc()

void findFromLocR(char **board, Move *move);

void findFromLocN(char **board, Move *move);

void findFromLocB(char **board, Move *move);

void findFromLocQ(char **board, Move *move);

void findFromLocK(char **board, Move *move);

void findFromLocP(char **board, Move *move);

// end Functional Prototypes (additional)

#endif
