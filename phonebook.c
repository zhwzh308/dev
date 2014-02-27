//
// APS105-F08 Lab 8 phonebook.c
//
// Program for maintaining a personal phone book.
//
// Uses a linked list to hold the phone book entries.
//
// Author: <Wenzhong Zhang>
// Student Number: <996711278>
//

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#define MAX_LENGTH 1023

//**********************************************************************
//  Linked List Definitions 
//  Define your linked list node and pointer types
//  here for use throughout the file.
//
//   ADD STATEMENT(S) HERE
typedef struct contact
{
	char familyName[MAX_LENGTH+1];
	char firstName[MAX_LENGTH+1];
	char address[MAX_LENGTH+1];
	char phoneNumber[MAX_LENGTH+1];
	struct contact *link;
//pointer to next node.
} contact;
//**********************************************************************
// Linked List Function Declarations
//
// Functions that modify the linked list.
//   Declare your linked list functions here.
//
//   ADD STATEMENT(S) HERE
//**********************************************************************
// Support Function Declarations
//
//Teacher's function:

void safegets (char s[], int arraySize);        // gets without buffer overflow
void familyNameDuplicate (char familyName[]);   // marker/tester friendly 
void familyNameFound (char familyName[]);       //   functions to print
void familyNameNotFound (char familyName[]);    //     messages to user
void familyNameDeleted (char familyName[]);
void phoneNumberFound (char phoneNumber[]);
void phoneNumberNotFound (char phoneNumber[]);
void printPhoneBookEmpty (void);
void printPhoneBookTitle (void);

//My funcs:

void newContact (char familyName[], char firstName[], char address[], char phoneNumber[], contact **p);//want to modify something
void contactDel (contact **p, char familyName[]);
/* remove head */
contact *contact_search (contact *c, char familyName[]);
/* By Family Name*/
contact *phone_search (contact *c, char phoneNumber[]);
void print_all (contact *head);
void DelAll (contact **p);

//**********************************************************************
// Program-wide Constants
//

const char NULL_CHAR = '\0';
const char NEWLINE = '\n';

//**********************************************************************
// Main Program
//
int main (void)
{
    contact *head=NULL;
    contact *temp=NULL;
    const char bannerString[]
        = "Personal Phone Book Maintenance Program.\n\n";
    const char commandList[]
        = "Commands are I (insert), D (delete), S (search by name),\n"
          "  R (reverse search by phone #), P (print), Q (quit).\n";

    // Declare linked list head.
    //   ADD STATEMENT(S) HERE TO DECLARE LINKED LIST HEAD.
 
    // announce start of program
    printf("%s",bannerString);
    printf("%s",commandList);
    
    char response;
    char res[MAX_LENGTH+1];
    char input[MAX_LENGTH+1];
	char familyName[MAX_LENGTH+1];
	char firstName[MAX_LENGTH+1];
	char address[MAX_LENGTH+1];
	char phoneNumber[MAX_LENGTH+1];
        //to pass char arrays to insert function
    do
    {
        printf("\nCommand?: ");
        safegets(input,MAX_LENGTH+1);
        // Response is first char entered by user.
        // Convert to uppercase to simplify later comparisons.
        response = toupper(input[0]);

        if (response == 'I')
        {
	    // Insert an phone book entry into the linked list.
            // Maintain the list in alphabetical order by family name.
            //   ADD STATEMENT(S) HERE
	    // USE THE FOLLOWING PRINTF STATEMENTS WHEN PROMPTING FOR DATA:
            printf("  family name: ");
	    fgets(familyName, MAX_LENGTH+1, stdin);
            printf("  first name: ");
	    fgets(firstName, MAX_LENGTH+1, stdin);
            printf("  address: ");
	    fgets(address, MAX_LENGTH+1, stdin);
            printf("  phone number: ");
	    fgets(familyName, MAX_LENGTH+1, stdin);
	    newContact(familyName, firstName, address, phoneNumber, &head);
        }
        else if (response == 'D')
        {
            // Delete an phone book entry from the list.
            //   ADD STATEMENT(S) HERE

            printf("\nEnter family name for entry to delete: ");
	    fgets(res,MAX_LENGTH,stdin);
	    contactDel(&head, res);
	    
        }
        else if (response == 'S')
        {
            // Search for an phone book entry by family name.

            printf("\nEnter family name to search for: ");
	    fgets(familyName, MAX_LENGTH, stdin);
            temp=contact_search(head, familyName);
            if (temp == NULL)
	        familyNameFound(res);
            else
	    {
	        printf("%s\n%s\n%s\n%s\n\n", temp->familyName, temp->firstName, temp->address, temp->phoneNumber);
	    }
            //   ADD STATEMENT(S) HERE

        }
        else if (response == 'R')
        {
            // Search for an phone book entry by phone number.
            //ADD STATEMENT(S) HERE
			printf("\nEnter phone number to search for: ");
            fgets(phoneNumber,MAX_LENGTH,stdin);
			temp = phone_search(head, phoneNumber);
			if (temp==NULL)
				phoneNumberNotFound(phoneNumber);
			else
			{
				phoneNumberFound(phoneNumber);
				printf("\n%s\n%s\n%s\n%s\n", temp->familyName, temp->firstName, temp->address, temp->phoneNumber);
			}
        }
        else if (response == 'P')
        {
            // Print the phone book.
            //   ADD STATEMENT(S) HERE
			print_all(head);
        }
        else if (response == 'Q')
        {
            ;// do nothing, we'll catch this below
        }
        else 
        {
            // do this if no command matched ...
            printf("\nInvalid command.\n%s\n",commandList);
        }
    } while (response != 'Q');
  
    // Delete the whole phone book linked list.
    //   ADD STATEMENT(S) HERE
    DelAll(&head);
    // Print the linked list to confirm deletion.
    //   ADD STATEMENT(S) HERE
    print_all (head);
    return 0;
}

//**********************************************************************
// Support Function Definitions

// Function to get a line of input without overflowing target char array.
void safegets (char s[], int arraySize)
{
    int i = 0, maxIndex = arraySize-1;
    char c;
    while (i < maxIndex && (c = getchar()) != NEWLINE)
    {
        s[i] = c;
        i++;
    }
    s[i] = NULL_CHAR;
}

// Function to call when user is trying to insert a family name 
// that is already in the book.
void familyNameDuplicate (char familyName[])
{
    printf("\nAn entry for <%s> is already in the phone book!\n"
           "New entry not entered.\n",familyName);
}

// Function to call when a family name was found in the phone book.
void familyNameFound (char familyName[])
{
    printf("\nThe family name <%s> was found in the phone book.\n",
             familyName);
}

// Function to call when a family name was not found in the phone book.
void familyNameNotFound (char familyName[])
{
    printf("\nThe family name <%s> is not in the phone book.\n",
             familyName);
}

// Function to call when a family name that is to be deleted
// was found in the phone book.
void familyNameDeleted (char familyName[])
{
    printf("\nDeleting entry for family name <%s> from the phone book.\n",
             familyName);
}

// Function to call when a phone number was found in the phone book.
void phoneNumberFound (char phoneNumber[])
{
    printf("\nThe phone number <%s> was found in the phone book.\n",
             phoneNumber);
}

// Function to call when a phone number was not found in the phone book.
void phoneNumberNotFound (char phoneNumber[])
{
    printf("\nThe phone number <%s> is not in the phone book.\n",
             phoneNumber);
}

// Function to call when printing an empty phone book.
void printPhoneBookEmpty (void)
{
    printf("\nThe phone book is empty.\n");
}

// Function to call to print title when whole phone book being printed.
void printPhoneBookTitle (void)
{
    printf("\nMy Personal Phone Book: \n");
}

//**********************************************************************
// Add your functions below this line.
//   ADD STATEMENT(S) HERE
void newContact (char familyName[], char firstName[], char address[], char phoneNumber[], contact **head)
{
    contact *testPtr=NULL;
    testPtr = contact_search (*head, familyName);
    if (strcmp(testPtr->familyName, familyName)==0)
    {
		familyNameDuplicate(familyName);
		return;
    }
	else
		testPtr = *head;
    for ( ; strcmp(testPtr->familyName, familyName) < 0; testPtr = testPtr -> link)
    ;
    contact *c = (contact *)malloc (sizeof(contact));//new node
    strcpy(c->familyName, familyName);
    strcpy(c->firstName, firstName);
    strcpy(c->address, address);
    strcpy(c->phoneNumber, phoneNumber);
    if (head==NULL)
	{
		c->link = *head;
		*head=c;
	}
	else
	{
		;
	}
}

void contactDel (contact **p, char familyName[]) /* remove head */
{
	contact *control=contact_search(*p, familyName);
	if (control != NULL)
	{
		contact *n = control;
		control = control -> link;
		free(n);
	}
}

void DelAll (contact **p)
{
	if (*p != NULL)
	{
		contact *n = *p;
		*p = (*p)->link;
		free(n);
	}
	return;
}

contact *contact_search (contact *c, char familyName[]) /* By Family Name*/
{
	while (c != NULL)
	{
		if (strcmp(c->familyName, familyName)==0)
		{
			return c;
		}
		c = c->link;
	}
	return NULL;
}

contact *phone_search (contact *c, char phoneNumber[])
{
	while (c != NULL)
	{
		if (strcmp(c->phoneNumber, phoneNumber)==0)
		{
			return c;
		}
		c = c->link;
	}
	return NULL;
}

void print_all (contact *head)
{
	if (head == NULL)
	{
		printPhoneBookEmpty();
	}
	else
	{
            printPhoneBookTitle();
	    while (head != NULL)
	        {
	            printf("%s\n%s\n%s\n%s\n\n", head->familyName, head->firstName, head->address, head->phoneNumber);
		    head = head->link;
	        }
	}
}
