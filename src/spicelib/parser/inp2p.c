/**********
Copyright 1992 Regents of the University of California.  All rights
reserved.
Author: 1992 Charles Hough
**********/

#include "ngspice.h"
#include <stdio.h>
#include "ifsim.h"
#include "inpdefs.h"
#include "inpmacs.h"
#include "fteext.h"
#include "inp.h"

void
INP2P(ckt,tab,current)
    void *ckt;
    INPtables *tab;
    card *current;

{

int mytype; /* the type we determine cpls are */
int type;   /* the type the model says it is */
char *line; /* the part of the current line left to parse */
char *name, *tempname; /* the cpl's name */
char *model;    /* the name of the cpl's model */
char **nname1;   /* the first node's name */
char **nname2;   /* the second node's name */
char *ground;
void **node1; /* the first node's node pointer */
void **node2; /* the second node's node pointer */
void *groundnode;
int error;      /* error code temporary */
int error1;     /* secondary error code temporary */
INPmodel *thismodel;    /* pointer to model structure describing our model */
void *mdfast;    /* pointer to the actual model */
void *fast;  /* pointer to the actual instance */
IFvalue ptemp;  /* a value structure to package cpl into */
IFuid uid;      /* uid for default model */
double lenval = 0;
int lenvalgiven = 0;
int num, i;

    mytype = INPtypelook("CplLines");
    if(mytype < 0 ) {
        LITERR("Device type CplLines not supported by this binary\n")
        return;
    }
    line = current->line;
    INPgetTok(&line,&name,1);
    INPinsert(&name,tab);
	/* num = (int) INPevaluate(&line,&error1,1); */
	num = 0;

	/* first pass to determine the dimension */
	while (*line != '\0') {
		INPgetTok(&line, &tempname,1);
		if (strcmp(tempname, "len") == 0) break;
		num ++;
	}
	num = (num - 2) / 2;
	line = current->line;
	INPgetTok(&line,&name,1);

	nname1 = (char **) malloc(num * sizeof(char *));
	nname2 = (char **) malloc(num * sizeof(char *));
	node1 = (void **) malloc(num * sizeof(void *));
	node2 = (void **) malloc(num * sizeof(void *));


	for (i = 0; i < num; i++) {
    	INPgetNetTok(&line,&(nname1[i]),1);
    	INPtermInsert(ckt,&(nname1[i]),tab,&(node1[i]));
	}
    INPgetTok(&line,&ground,1);
    INPtermInsert(ckt,&ground,tab,&groundnode);
	for (i = 0; i < num; i++) {
		INPgetNetTok(&line,&(nname2[i]),1);
		INPtermInsert(ckt,&(nname2[i]),tab,&(node2[i]));
	}
    INPgetTok(&line,&ground,1);
    INPtermInsert(ckt,&ground,tab,&groundnode);

	INPgetTok(&line,&model,1);
	if (strcmp(model, "len") == 0) {
		lenval = INPevaluate(&line,&error1,1);
		lenvalgiven = 1;
		INPgetTok(&line,&model,1);
	}
	if(*model) { /* token isn't null */
		INPinsert(&model,tab);
		thismodel = (INPmodel *)NULL;
		current->error = INPgetMod(ckt,model,&thismodel,tab);
		if(thismodel != NULL) {
			if(mytype != thismodel->INPmodType) {
				LITERR("incorrect model type")
				return;
			}
			mdfast = thismodel->INPmodfast;
			type = thismodel->INPmodType;
		} else {
			type = mytype;
			if(!tab->defPmod) {
				/* create default P model */
				IFnewUid(ckt,&uid,(IFuid)NULL,"P",UID_MODEL,(void**)NULL);
				IFC(newModel, (ckt,type,&(tab->defPmod),uid))
			}
			mdfast = tab->defPmod;
    	}
    	IFC(newInstance,(ckt,mdfast,&fast,name))
	} else  {
		LITERR("model name is not found")
		return;
	}

    /* IFC(bindNode,(ckt,fast,1,fakename)) */

	ptemp.iValue = num;
	GCA(INPpName,("dimension", &ptemp,ckt,type,fast))
	ptemp.v.vec.sVec = nname1;
	GCA(INPpName,("pos_nodes", &ptemp,ckt,type,fast))
	ptemp.v.vec.sVec = nname2;
	GCA(INPpName,("neg_nodes", &ptemp,ckt,type,fast))
	if (error1 == 0 && lenvalgiven) {
		ptemp.rValue = lenval;
		GCA(INPpName,("length",&ptemp,ckt,type,fast))
	}

    return;
}
