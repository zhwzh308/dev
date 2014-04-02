/*
Code developed for Lab 4 ECE361.
Author: Wenzhong Zhang
Student Number: 996711278
*/

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<errno.h>
#include<sys/types.h>
#include<sys/socket.h>
#include<netinet/in.h>
#include<arpa/inet.h>
#include<netdb.h>
#include<unistd.h>
#include<errno.h>

#define MAX_CLIENTS 10
#define BUFFER_LENGTH 1024
#define SERVER_PORT 3520

void handle_client(int sock, char **clientlist){
    int i, n;
    char buffer[1024];
    char clientname[16];
    char otheruser[16];
    char *broadcast = NULL;
    char *privatechat = NULL;
    
    memset(buffer, 0, 1024);
    memset(clientname, 0, 16);
    //memset(otheruser, 0, 16);
    n = recv(sock, clientname, 16, 0);
    n = send(sock, "WELCOME", 7, 0);
    
    for (i = 0; clientlist[i][0] != NULL; i++) {
        ;
    }
    strcpy(clientlist[i], clientname);
    
    printf("User %s connected to chat server!\n", clientname);
    while (1) {
        memset(buffer, 0, 1024);
        n = recv(sock, buffer, 1024, 0);
        
        if (n < 0) {
            perror("recv()");
            exit(-1);
        }//printf("RAW message |%s|\n", buffer);
        
        n = send(sock, "ACK", 4, 0);
        if (n < 0) {
            perror("send()");
        }
        
        
        if (strcmp(buffer, "list") == 0) {
            printf("(Address:%d)User %s requested list\n", (int) clientlist, clientname);
            for (i = 0; i < 10; i++) {
                if (clientlist[i][0] == NULL) {
                    sprintf(buffer, "%d: empty\n", i + 1);
                    send(sock, buffer, strlen(buffer), 0);
                    memset(buffer, 0, BUFFER_LENGTH);
                }
                else {
                    //printf("%d: %s\n", i, clientlist[i]);
                    sprintf(buffer, "%d: %s\n", i + 1, clientlist[i]);
                    send(sock, buffer, strlen(buffer), 0);
                    memset(buffer, 0, BUFFER_LENGTH);
                }
            }
            send(sock, "\n----- End of list -----\n", 64, 0);
            printf("List sent to %s!\n", clientname);
            continue;
        }
        if (buffer[0] == '|' && buffer[1] == '|' && buffer[2] == '|') {//broadcast
            broadcast = &(buffer[3]);
            printf("***** %s to ALL |%s| *****\n", clientname, broadcast);
            continue;
        }
        if (strcmp(buffer, "exit") == 0) {//exit
            printf("!***** %s has left chat! *****!\n", clientname);
            break;
        }
        //private chat
        memset(otheruser, 0, 16);
        for (n = 0; (buffer[n] != ' ') && (n < 16); n++) {
            otheruser[n] =  buffer[n];
        }
        otheruser[15] = 0;
        privatechat = &(buffer[n+1]);
        if (otheruser != NULL)
            printf("***** %s private chat to {%s}:\t|%s| *****\n", clientname, otheruser, privatechat);
    }
    close(sock);
    return ;//the rest of main should close this connection.
}

int main (int argc, char *argv[]) {//chatserver [server_port]
	//usage include case where server port not specified.
	int parentfd, childfd, i, error, message_size;
	uint16_t port;
	pid_t childpid;
    
    pid_t *clientgroup = NULL;
    //malloc 10 places for pids
    i = MAX_CLIENTS * sizeof (pid_t);
    clientgroup = (pid_t *) malloc ( i );
    if (clientgroup < 0)
        perror("Unable to find space! malloc()");
    memset(clientgroup, 0, i);
    free(clientgroup);
    
    //int *pid_index;
	socklen_t clientlen;//client's addr byte size.
	struct sockaddr_in serveraddr, clientaddr, *sockaddr_ipv4;
	struct addrinfo hints, *res=NULL, *res0=NULL;//points to return of getaddrinfo().
	struct hostent *hostp, *server;//client , server info.
	struct in_addr ipv4addr;
	memset(&serveraddr, 0, sizeof serveraddr);
	memset(&clientaddr, 0, sizeof clientaddr);
	memset(&hints,0,sizeof hints);
	memset(&ipv4addr, 0, sizeof(ipv4addr));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;


	char *hostaddrp;//client host ip
    char **clientlist;
    clientlist = malloc(MAX_CLIENTS * sizeof (*clientlist));
	char servername[255];//Max servername length
	char serverip[16];
	char portstring[6];
	char buffer[BUFFER_LENGTH];//1024
	//use GETHOSTNAME.



	for (i = 0; i < MAX_CLIENTS; i++) {
        clientlist[i] = malloc(17 * sizeof (char));
		memset(clientlist[i], 0, 16);
    }
	memset(servername, 0, sizeof servername);
	memset(serverip, 0, sizeof serverip);
	memset(portstring, 0, sizeof portstring);
	memset(&childpid, 0, sizeof childpid);
	memset(&clientlen, 0, sizeof clientlen);
	//Precaution: 0 out every thing! fuck
	//array to store clients.
    
    //printf("client addr %d\n", (int) clientlist);

	if (argc > 2) {
		perror("Usage error. only port number or none argument allowed.");
		exit(-1);
	} else {
		if (argc == 1)
			port = SERVER_PORT;
		else
			port = atoi(argv[1]);
		//SET PORT
		parentfd = socket(AF_INET, SOCK_STREAM, 0);
		if (parentfd < 0) {
			perror("Socket creation failure, quitting.");
			exit(-1);
		}// else
		//	printf("parentfd socket() OK! ");
        
		sprintf(portstring, "%d", port);
		serveraddr.sin_family = AF_INET;
		serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
		//SYSTEM WILL FIGURE OUT THE ADDR.
		serveraddr.sin_port = htons((unsigned short) port);


		if (gethostname(servername,sizeof(servername)) == -1)
			perror("gethostname()");

		if (getaddrinfo(servername, portstring, &hints, &res0) == -1) {
			fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(error));
			perror("getaddrinfo()");
		}
		//get info on this machine.
		sockaddr_ipv4 = (struct sockaddr_in *) res0->ai_addr;
        printf("Server on %s (%s:%s) is running!\t", servername, inet_ntoa(sockaddr_ipv4->sin_addr), portstring);

        if(bind(parentfd, (struct sockaddr *) &serveraddr, sizeof(serveraddr)) == -1) {
            perror("bind()");
            close(parentfd);
            exit(EXIT_FAILURE);
        }
		//bind parentfd
		if (listen(parentfd, 1) < 0) {
			perror("listen()");
            close(parentfd);
            exit(EXIT_FAILURE);
        }
        //listen on parentfd
		clientlen = sizeof(clientaddr);

		for (;;) {
			//now we accept connections
			childfd = accept(parentfd, (struct sockaddr *) &clientaddr, &clientlen);
            //block until connect.
			if (childfd < 0) {
				//perror("ERROR accepting connections.");
                exit(-1);
            }

            childpid = fork();

            if (childpid == -1) {
                perror("fork()");
                exit(-1);
            }
            if (childpid == 0) {//success
                close(parentfd);
                hostp = gethostbyaddr((const char *)&clientaddr.sin_addr.s_addr, sizeof(clientaddr.sin_addr.s_addr), AF_INET);
                if (hostp == NULL) {
                    perror("Client host IP invalid.\n");
                    exit(-1);
                }
                hostaddrp = inet_ntoa(clientaddr.sin_addr);
                //Client IP
                if (hostaddrp == NULL)
                    printf("error on inet_ntoa.\n");
                printf("Server connected with %s %s\n", hostp->h_name, hostaddrp);
                handle_client(childfd, clientlist);
//                handle_client(childfd);
                close(childfd);
            } else
                close(childfd);
		}
        free(clientlist);
        close(parentfd);
			// till else end.
	} //end of server.
	return 0;
}

