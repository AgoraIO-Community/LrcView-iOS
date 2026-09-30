/*************************************************************
 * Author:	Lionfore Hao (haolianfu@agora.io)
 * Date	 :	Jul 26th, 2018
 * Module:	AOSL version definitions.
 *
 *
 * This is a part of the Advanced Operating System Layer.
 * Copyright (C) 2018 Agora IO
 * All rights reserved.
 *
 ************************************************************/

#ifndef __AOSL_VERSION_H__
#define __AOSL_VERSION_H__

#include <aosl/api/aosl_defs.h>

#ifdef __cplusplus
extern "C" {
#endif



/**
 * Get the build-time AOSL version string.
 * Return value:
 *      a static version string, no need to free.
 **/
extern __aosl_api__ const char *aosl_get_version ();

/**
 * Get the build-time Git branch string.
 * Return value:
 *      a static branch string, no need to free.
 **/
extern __aosl_api__ const char *aosl_get_git_branch ();

/**
 * Get the build-time Git commit string.
 * Return value:
 *      a static commit string, no need to free.
 **/
extern __aosl_api__ const char *aosl_get_git_commit ();



#ifdef __cplusplus
}
#endif


#endif /* __AOSL_VERSION_H__ */
