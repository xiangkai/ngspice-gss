#include <ngspice.h>
#include <mif.h>
#include <cm.h>
#include <dllitf.h>


/*how annoying!, needed for structure below*/
void *tcalloc(size_t a, size_t b){
  return tmalloc(a*b);
}

static void *empty(void){
  return NULL;
}

struct coreInfo_t  coreInfo =
{
  MIF_INP2A,
  MIFgetMod,
  MIFgetValue,
  MIFsetup,
  MIFunsetup,
  MIFload,
  MIFmParam,
  MIFask,
  MIFmAsk,
  MIFtrunc,
  MIFconvTest,
  MIFdelete,
  MIFmDelete,
  MIFdestroy,
  MIFgettok,
  MIFget_token,
  MIFget_cntl_src_type,
  MIFcopy,
  cm_climit_fcn,
  cm_smooth_corner,
  cm_smooth_discontinuity,
  cm_smooth_pwl,
  cm_analog_ramp_factor,
  cm_analog_alloc,
  cm_analog_get_ptr,
  cm_analog_integrate,
  cm_analog_converge,
  cm_analog_set_temp_bkpt,
  cm_analog_set_perm_bkpt,
  cm_analog_not_converged,
  cm_analog_auto_partial,
  cm_event_alloc,
  cm_event_get_ptr,
  cm_event_queue,
  cm_message_get_errmsg,
  cm_message_send,
  cm_netlist_get_c,
  cm_netlist_get_l,
  cm_complex_set,
  cm_complex_add,
  cm_complex_subtract,
  cm_complex_multiply,
  cm_complex_divide,
  (FILE *(*)(void))empty,
  (FILE *(*)(void))empty,
  (FILE *(*)(void))empty,
#ifndef HAVE_LIBGC
  tmalloc,
  tcalloc,
  trealloc,
  txfree,
  (char *(*)(int))tmalloc,
  (char *(*)(char *,int))trealloc,
  (void (*)(char *))txfree
#else
  GC_malloc,
  tcalloc,
  GC_realloc,
  (void (*)(void *))empty,
  (char *(*)(int))GC_malloc,
  (char *(*)(char *,int))GC_realloc,
  (void (*)(char *))empty      
#endif
};
