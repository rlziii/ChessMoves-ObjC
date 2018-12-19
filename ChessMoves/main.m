#import <Foundation/Foundation.h>
#import "ChessMoves.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        char **board = createChessBoard();
        printChessBoard(board);
    }
    
    return 0;
}
