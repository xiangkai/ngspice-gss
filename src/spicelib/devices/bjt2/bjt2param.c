/**********
Copyright 1990 Regents of the University of California.  All rights reserved.
Author: 1985 Thomas L. Quarles
Modified: Alan Gillespie
**********/
/*
 */

/*
 * This routine sets instance parameters for
 * BJT2s in the circuit.
 */

#include "ngspice.h"
#include <stdio.h>
#include "const.h"
#include "ifsim.h"
#include "bjt2defs.h"
#include "sperror.h"
#include "suffix.h"


/* ARGSUSED */
int
BJT2param(param,value,instPtr,select)
    int param;
    IFvalue *value;
    GENinstance *instPtr;
    IFvalue *select;
{
    BJT2instance *here = (BJT2instance*)instPtr;

    switch(param) {
        case BJT2_AREA:
            here->BJT2area = value->rValue;
            here->BJT2areaGiven = TRUE;
            break;
        case BJT2_TEMP:
            here->BJT2temp = value->rValue+CONSTCtoK;
            here->BJT2tempGiven = TRUE;
            break;
        case BJT2_OFF:
            here->BJT2off = value->iValue;
            break;
        case BJT2_IC_VBE:
            here->BJT2icVBE = value->rValue;
            here->BJT2icVBEGiven = TRUE;
            break;
        case BJT2_IC_VCE:
            here->BJT2icVCE = value->rValue;
            here->BJT2icVCEGiven = TRUE;
            break;
        case BJT2_AREA_SENS:
            here->BJT2senParmNo = value->iValue;
            break;
        case BJT2_IC :
            switch(value->v.numValue) {
                case 2:
                    here->BJT2icVCE = *(value->v.vec.rVec+1);
                    here->BJT2icVCEGiven = TRUE;
                case 1:
                    here->BJT2icVBE = *(value->v.vec.rVec);
                    here->BJT2icVBEGiven = TRUE;
                    break;
                default:
                    return(E_BADPARM);
            }
            break;
        default:
            return(E_BADPARM);
    }
    return(OK);
}