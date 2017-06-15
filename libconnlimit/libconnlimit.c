#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "/usr/include/hiredis/hiredis.h"

 
// 将str字符以spl分割,存于dst中，并返回子字符串数量
int split(char dst[][240], char* str, const char* spl)
{
    int n = 0;
    char *result = NULL;
    result = strtok(str, spl);
    while( result != NULL )
    {
        strcpy(dst[n++], result);
        result = strtok(NULL, spl);
    }
    return n;
}

int clear_used_token_list(char* index){
    redisContext *c;
    redisReply *reply;

    const char* server_ip = "192.168.9.236";
    int port = 2502;
    struct timeval timeout = {0,10000};
    c = redisConnectWithTimeout(server_ip,port,timeout);
    if (c == NULL || c->err){
        if(c){
            printf("Connection error: %s\n",c->errstr);
            redisFree(c);
        }
        else{
            printf("Connection error: can't allocate redis context\n");
        }
        return 0;
    }
    char* used_token_key_name_buffer = malloc(sizeof(char)*256);
    char* idle_token_key_name_buffer = malloc(sizeof(char)*256);
    char* config_token_key_name_buffer = malloc(sizeof(char)*256);
    char* uri = malloc(sizeof(char)*256-10);
    reply = redisCommand(c,"keys qos:*:%s:used", index);
    if (reply == NULL){
        return 0;
    }
    if (reply->type != REDIS_REPLY_ARRAY){
        return 0;
    }
    int idx = 0;
    for(idx;idx<reply->elements;idx++){
        char dst[4][240];
        int clean_key=0;
        split(dst,reply->element[idx]->str,":");
        printf("idx: %d, return value is: %s\n",idx,dst[1]);
        memset(used_token_key_name_buffer,'\0',256);
        memset(idle_token_key_name_buffer,'\0',256);
        memset(config_token_key_name_buffer,'\0',256);
        sprintf(used_token_key_name_buffer,"qos:%s:%s:used",dst[1],index);
        sprintf(idle_token_key_name_buffer,"qos:%s:idle",dst[1]);
        sprintf(config_token_key_name_buffer,"qos:config:%s",dst[1]);
        redisReply* reply_used_list;
        redisReply* reply_idle;
        reply_idle = redisCommand(c,"exists %s", config_token_key_name_buffer);
        if(reply_idle == NULL || reply_idle->type == REDIS_REPLY_ERROR){
            printf("check idle list error: %s\n",reply_idle);
            return 0;
        }
        if(reply_idle->type == REDIS_REPLY_INTEGER){
            clean_key = reply_idle->integer;
            printf("check idle list result: %d uri: %s index: %d\n",clean_key,uri,index);
        }

        if(clean_key == 0){
            reply_used_list = redisCommand(c,"del %s", used_token_key_name_buffer);
        }
        else{

            reply_used_list = redisCommand(c,"LRANGE %s 0 -1", used_token_key_name_buffer);
            if (reply_used_list == NULL || reply_used_list->type == REDIS_REPLY_ERROR){
                return 0;
            }

            if (reply_used_list->type == REDIS_REPLY_ARRAY) {
                int j = 0;
                for (; j < reply_used_list->elements;j++) {
                    redisReply *reply_temp;
                    printf("%d) %s : elements: %d\n", j, reply_used_list->element[j]->str, reply_used_list->elements);
                    reply_temp = redisCommand(c,"lpush %s 0",idle_token_key_name_buffer);
                    if(reply_temp == NULL || reply_temp->type == REDIS_REPLY_ERROR){
                        printf("give token back faled\n");
                        return 0;
                    }
                    reply_temp = redisCommand(c,"lpop %s",used_token_key_name_buffer);
                    if(reply_temp == NULL || reply_temp->type == REDIS_REPLY_ERROR){
                        printf("remove token from used list faled\n");
                        return 0;
                    }
                    freeReplyObject(reply_temp);
                }
            }
        }
        freeReplyObject(reply_idle);
        freeReplyObject(reply_used_list);
    }

    freeReplyObject(reply);

    redisFree(c);
    return 1;
}

int release_token(char* index,char* uri){
    printf("index is: %s. uri is: %s ",index,uri);
    redisContext *c;
    redisReply *reply;
    const char* server_ip = "192.168.9.236";
    int port = 2502;
    struct timeval timeout = {0,10000};
    c = redisConnectWithTimeout(server_ip,port,timeout);
    if (c == NULL || c->err){
        if(c){
            printf("Connection error: %s\n",c->errstr);
            redisFree(c);
        }
        else{
            printf("Connection error: can't allocate redis context\n");
        }
        return 0;
    }
    char* used_token_key_name_buffer = malloc(sizeof(char)*256);
    char* idle_token_key_name_buffer = malloc(sizeof(char)*256);
    char* config_token_key_name_buffer = malloc(sizeof(char)*256);
    sprintf(used_token_key_name_buffer,"qos:%s:%s:used",uri,index);
    sprintf(idle_token_key_name_buffer,"qos:%s:idle",uri);
    sprintf(config_token_key_name_buffer,"qos:config:%s",uri);
    redisReply* reply_idle;
    reply_idle = redisCommand(c,"exists %s", config_token_key_name_buffer);
    if(reply_idle == NULL || reply_idle->type == REDIS_REPLY_ERROR){
        printf("check idle list error: %s\n",reply_idle);
        freeReplyObject(reply_idle);
        redisFree(c);
        return 0;
    }
    if(reply_idle->type == REDIS_REPLY_INTEGER){
        freeReplyObject(reply_idle);
        printf("check idle list result: %d index: %s uri: %s \n",clean_key,index,uri);
    }

    if(reply_idle->integer == 0){
        freeReplyObject(reply_idle);
        redisFree(c);
        return 1;
    }
    else{
        reply = redisCommand(c,"lpop %s", used_token_key_name_buffer);
        if(reply == NULL || reply->type == REDIS_REPLY_ERROR || reply->type == REDIS_REPLY_NIL){
            printf("pop token from used list faileed\n");
            freeReplyObject(reply);
            redisFree(c);
            return 0;
        }
        
        reply = redisCommand(c,"lpush %s i",idle_token_key_name_buffer);
        if(reply == NULL || reply->type == REDIS_REPLY_ERROR){
            freeReplyObject(reply);
            redisFree(c);
            return 0;
        }
    }
    freeReplyObject(reply);
    redisFree(c);
    return 1;
}

//gcc qos.c -lhiredis --standalone exec
//gcc -c -fpic qos.c
//gcc -shared qos.o -o libqos.so -lhiredis
