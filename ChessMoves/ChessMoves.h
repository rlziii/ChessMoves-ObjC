#import <Foundation/Foundation.h>

#ifndef __CHESSMOVES_H
#define __CHESSMOVES_H

typedef enum {
    BLACK,
    WHITE
} Color;

typedef struct Game
{
    // array of algebraic chess notation strings
    char **moves;
    
    // number of strings in the 'movse' array
    int numMoves;
} Game;

typedef struct Location
{
    // the square's column ('a' through 'h')
    char col;
    
    // the square's row (1 through 8)
    int row;
} Location;

typedef struct Move
{
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

// Functional Prototypes

char **createChessBoard(void);

char **destroyChessBoard(char **board);

void printChessBoard(char **board);

char **playTheGame(Game *g);

void parseNotationString(char *str, Move *whiteMove, Move *blackMove);

void movePiece(char **board, Move *move);

void findFromLoc(char **board, Move *move);

double difficultyRating(void);

double hoursSpent(void);

#endif
