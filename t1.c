#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int clear_used_token_list(char* index);
int release_token(char* index,char* uri);
int main(int argc,char* argv){
    char* idx = "22";
    int ret = 0;
    ret = release_token(idx,"/");
    if(0==ret){
        printf("clear used token list for idx: %s failed\n",idx);
    }
    else{
        printf("clear success\n");
    }
}
//compile command: gcc t1.c -lconnlimit -lhiredis
