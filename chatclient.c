/*
Code developed for Lab 4 ECE361.
Author: Wenzhong Zhang
Student Number: 996711278
Lab4 chat room client
*/

#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#include<string.h>
#include<errno.h>
#include<sys/types.h>
#include<sys/socket.h>
#include<netinet/in.h>
#include<arpa/inet.h>
#include<netdb.h>
#include<unistd.h>
#include<errno.h>

#define USER_LENGTH 16
#define BUFFER_LENGTH 1024
#define SERVER_PORT 3520

bool is_ip (char *address) {
    int i, j;
    j = strlen(address);
    bool flag = true;
    printf("is_ip: the string length is %d characters.\t", j);
    if (j > 15) {
        printf("server address not an IP");
        return false;
    } else {
        for (i = 0; i < j; i++) {
            if (address[i] == '.') {
                continue;
            }else if (address[i] < '0' || address[i] > '9') {
                flag = false;
                break;
            }
        }
    }/*
    if (i == j) {
        printf("Reached end of argv[1]\n");
    } else {
        printf("The argument is not an ip.\n");
    }*/
    return flag;
}


int main (int argc, char *argv[]) {
    int sd, portno, error;//send, receive, and error for getaddrinfo.
    int i=0;
    struct sockaddr_in servaddr, *sockaddr_ipv4;
    //struct sockaddr_storage servaddr;
    memset(&servaddr, 0, sizeof servaddr);
    struct addrinfo hints, *result = NULL, *ptr = NULL;
    //For use with getaddrinfo.
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    struct hostent *server;
    struct in_addr ipv4addr;
    memset(&ipv4addr, 0, sizeof ipv4addr);
    
    char *hostaddrp;//ip of this client.
    char buffer[BUFFER_LENGTH];
    char command[USER_LENGTH];
    char message[BUFFER_LENGTH];
    socklen_t addrlen;//server addr byte size.
    memset(&addrlen, 0, sizeof addrlen);
    memset(buffer, 0, sizeof buffer);
    
    
    if (argc != 4) {
        printf("Client usage: %s [server address] [server port] [username]\n", argv[0]);
        perror("Program ran with wrong arguments");
        exit(-1);
    } else {
        if (strlen(argv[3]) > USER_LENGTH) {
            printf("YOUR %s USERNAME EXCEEDED LIMIT. Supports only %d characters username!\nCANNOT START CLIENT...\n", argv[3], USER_LENGTH);
            return 0;
        }
        portno = atoi(argv[2]);
        printf("Client initialized.\t");
        if ((error = getaddrinfo(argv[1], argv[2], &hints, &result)) != 0) {
            fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(error));
            return 1;
        }
        printf("Connecting server |%s:%s|\n", argv[1], argv[2]);
        
        sd = socket(AF_INET, SOCK_STREAM, 0);
        //socket
        if (sd < 0) {
            perror("Unable to create socket.");
            exit(-1);
        } //else
           // printf("socket() = %d\t", sd);
        server = gethostbyname(argv[1]);
        if (server == NULL) {
            fprintf(stderr,"ERROR, no such host");
            close(sd);
            exit(-1);
        }
        
        servaddr.sin_family = AF_INET;
        bcopy((char *)server->h_addr, (char *)&servaddr.sin_addr.s_addr, server->h_length);
        servaddr.sin_port = htons(portno);
        
        if (connect(sd, result->ai_addr, result->ai_addrlen) == -1) {
            perror("connect()");
            close(sd);
            exit(-1);
        } else
            printf("connected!\n");
        //connect
        if (send(sd, argv[3], strlen(argv[3]), 0) == -1)
            perror("send()");
        //send username
        
        //NOW WE CAN PERFORM READ AND WRITE OP's
        while (1) {
            recv(sd, buffer, BUFFER_LENGTH, 0);
            /*
            if (recv(sd, buffer, BUFFER_LENGTH, 0) == -1) {
                perror("recv()");
                exit(0);
            }
            */
            //printf("%s\n",buffer);
            //if (strcmp("ACK") == 0)
            if (strcmp(buffer, "ACK") == 0)
                printf("Message sent.\n", buffer);
            else if (strcmp(buffer, "WELCOME") != 0) {
                printf("%s\n",buffer);
                continue;
            }
            memset(buffer, 0, BUFFER_LENGTH);
            memset(command, 0, USER_LENGTH);
            fscanf(stdin, "%s", command);
            //printf("command |%s|\n",command);
            if (strcmp(command, "exit") == 0) {
                printf("Thanks for using client. Goodbye\n");
                send(sd, "exit", 4, 0);
                break;
            } else if (strcmp(command, "list") == 0) {
                send(sd, "list", 4, 0);
                printf("************* Client List *************\n");
                //recv(sd, buffer, BUFFER_LENGTH, 0);
                continue;
            } else if (strcmp(command, "broadcast") == 0) {
                fscanf(stdin, " %[^\n]s", buffer);
                sprintf(message, "|||%s", buffer);
                printf("\nTo ALL:\t%s\n\n", buffer);
                send(sd, message, strlen(message), 0);
            }
            else {
                fscanf(stdin, " %[^\n]s", buffer);
                printf("\nTo %s:\t%s\n\n",command, buffer);
                sprintf(message, "%s %s", command, buffer);
                //printf("Message to be sent: |%s|", message);
                if (send(sd, message, strlen(message), 0) == -1)
                    perror("send()");
            }
            
        }
    }
    freeaddrinfo(result);
    close(sd);
    return 0;
}
