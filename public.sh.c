char *functions;
char *includes;
char *main_body;
char iv[17]="\0";
char key[33]="\0";
char prod_serial[256]="/sys/devices/virtual/dmi/id/product_serial";
char prod_uuid[256]="/sys/devices/virtual/dmi/id/product_uuid";
#include <fcntl.h>
#include <openssl/buffer.h>
#include <openssl/conf.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
int ctx_len=17424;
unsigned char *crypted_script="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\n"
;
unsigned char uuid[37]="aa546f28-99a0-0a2f-50b5-fddc66de1b7b";
unsigned char serial[17]="5cfcc245be5b87ad";
int getuuid(char *uuid)
{ FILE *filepointer;
  int i=0,rb=0;
  char *s, *end;
  if((filepointer=fopen(prod_uuid,"r"))==NULL)
  {
#ifdef __linux__
    if((filepointer=popen("dmidecode -s system-uuid","r"))==NULL)
    { return(-1); /*failed running dmidecode*/
    }
#elif __APPLE__
    if((filepointer=popen("system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }'","r"))==NULL)
    { return(-1); /*failed running system_profiler */
    }
#elif __FreeBSD__
    if((filepointer=popen("gpart list | awk -v i=0 '/rawuuid:/ {if (i<1) print $NF; i++}'","r"))==NULL)
    { return(-1); /*failed running gpar or awk */
    }
#elif __OpenBSD__
    if((filepointer=popen("disklabel $(df / |awk -F'[/ ]' 'END{print $3}') | awk '/duid:/ {print $NF}' |md5 |awk '{printf(\"%sopen\",$1)}'","r"))==NULL)
    { return(-1); /*failed running disklabel, md5 or awk */
    }
#else
    printf("Unsupported platform\n");
    return(-1);
#endif
    if((rb=fread(uuid,1,36,filepointer))!=36)
    { return(-2); /*could not read enough data from "dmidecode -s system-uuid"*/
    } else pclose(filepointer);
  } else
  {
    if((rb=fread(uuid,1,36,filepointer))!=36)
    { return(-3); /*could not read enough data from prod_uuid*/
    } else fclose(filepointer);
  }
  return strlen(uuid); 
}
int makekey (char *key , char *uuid)
{ int i=0;
  char *s, *end; 
  s=(char*)uuid;
  while (*s)
  { if ( *s != '-') key[i++]=*s;
    s++;
  }
  return strlen(key);
}
int getserial(char *serial)
{ FILE *filepointer;
  int rb=0;
  char *s, *end;
  char buff[17]="\0";
  /* attempt to open sys produtc serial */
  if((filepointer=fopen(prod_serial,"r"))==NULL)
  { //printf("File open error. Will attempt to use dmidecode.\n");
#ifdef __linux__
    if((filepointer=popen("dmidecode -s system-serial-number","r"))==NULL)
    { return(-1); /* failed running dmidecode */
    }
#elif __APPLE__
    if((filepointer=popen("system_profiler SPHardwareDataType | awk '/Serial Number/ { print $4 }'","r"))==NULL)
    { return(-1); /* failed running system_profiler */
    }
#elif __FreeBSD__
    if((filepointer=popen("gpart list | awk -v i=0 '/rawuuid:/ {if (i==2) {print $NF;} i++}'","r"))==NULL)
    { return(-1); /*failed running gpart or awk */
    }
#elif __OpenBSD__
    if((filepointer=popen("disklabel $(df / |awk -F'[/ ]' 'END{print $3}') | awk '/duid:/ {print $NF}'","r"))==NULL)
    { return(-1); /*failed running disklabel or awk */
    }
#else
    printf("Unsupported platform\n");
    return(-1);
#endif    
    rb=fread(buff,1,16,filepointer);
    pclose(filepointer);
  } else
  {
    rb=fread(buff,1,16,filepointer);
    fclose(filepointer);
  }
  if(rb<1)
  { /*if you get in in here nothing was read so migh as well just give up */
    printf("Insufficient data to identify.\n");
    exit(1);
  }
  if(rb!=16) strncpy(serial,buff,rb-1);
  else strcpy(serial,buff);
  serial[rb]=0;
  return strlen(serial);
}
int makeiv (char *iv, char *serial)
{ FILE *filepointer;
  int rb=0;
  char *s, *end;
  rb=strlen(serial);
  if(rb!=16)
  { strncat(iv,serial,rb-1);
    if(rb<9)  strncat(iv,prod_serial,17-rb);
    strncat(iv,serial,17-rb);
  } else strcpy(iv,serial);
  return strlen(iv);
}
int obencrypt(unsigned char *plaintext, int plaintext_len, unsigned char *key, unsigned char *iv, unsigned char *ciphertext)
{ EVP_CIPHER_CTX *ctx;
  int len;
  int ciphertext_len;
  /* Create and initialise the context */
  if(!(ctx = EVP_CIPHER_CTX_new())) exit(1);
  /* Initialise the encryption operation. IMPORTANT - ensure you use a key
   * and IV size appropriate for your cipher
   * In this example we are using 256 bit AES (i.e. a 256 bit key). The
   * IV size for *most* modes is the same as the block size. For AES this
   * is 128 bits */
  if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv))
    exit(1);
  /* Provide the message to be encrypted, and obtain the encrypted output.
   * EVP_EncryptUpdate can be called multiple times if necessary*/
  if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
    exit(1);
  ciphertext_len = len;
  /* Finalise the encryption. Further ciphertext bytes may be written at
   * this stage.*/
  if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len)) exit(1);
  ciphertext_len += len;
  /* Clean up */
  EVP_CIPHER_CTX_free(ctx);
  return ciphertext_len;
}
int decrypt(unsigned char *ciphertext, int ciphertext_len, unsigned char *key, unsigned char *iv, unsigned char *plaintext)
{ EVP_CIPHER_CTX *ctx;
  int len;
  int plaintext_len;
  /* Create and initialise the context */
  if(!(ctx = EVP_CIPHER_CTX_new())) exit(1);
  /* Initialise the decryption operation. IMPORTANT - ensure you use a key
   * and IV size appropriate for your cipher
   * In this example we are using 256 bit AES (i.e. a 256 bit key). The
   * IV size for *most* modes is the same as the block size. For AES this
   * is 128 bits */
  if(1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv))
    exit(1);
  /* Provide the message to be decrypted, and obtain the plaintext output.
   * EVP_DecryptUpdate can be called multiple times if necessary*/
  if(1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
    exit(1);
  plaintext_len = len;
  /* Finalise the decryption. Further plaintext bytes may be written at
   * this stage.*/
  if(1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len)) exit(1);
  plaintext_len += len;
  /* Clean up */
  EVP_CIPHER_CTX_free(ctx);
  return plaintext_len;
}
char *unbase64(unsigned char *input, int length)
{ BIO *b64, *bmem;
  char *buffer = (char *)malloc(length);
  memset(buffer, 0, length);
  b64 = BIO_new(BIO_f_base64());
  bmem = BIO_new_mem_buf(input, length);
  bmem = BIO_push(b64, bmem);
  BIO_read(bmem, buffer, length);
  BIO_free_all(bmem);
  return buffer;
}
char *base64(const unsigned char *input, int length)
{ BIO *bmem, *b64;
  BUF_MEM *bptr;
  b64 = BIO_new(BIO_f_base64());
  bmem = BIO_new(BIO_s_mem());
  b64 = BIO_push(b64, bmem);
  BIO_write(b64, input, length);
  BIO_flush(b64);
  BIO_get_mem_ptr(b64, &bptr);
  char *buff = (char *)malloc(bptr->length);
  memcpy(buff, bptr->data, bptr->length-1);
  buff[bptr->length-1] = 0;
  BIO_free_all(b64);
  return buff;
}
int mk_sh_c ( char *infilename, char *key, char *iv , bool reusable, char *serial, char *uuid)
{ unsigned char *plaintext, *ciphertext, *b64ctx;
  char *outfilename;
  FILE *infile,*outfile;
  int rb,insize,ctsize,i; 
  char str[256]="\0";
  outfilename=malloc(strlen(infilename)+2);
  strcpy(outfilename,infilename);
  strcat(outfilename,".c");
  if((outfile=fopen(outfilename,"wb"))==NULL)
  return(-1); /*failed opening intermediate c source file*/
  if((infile=fopen(infilename,"r"))==NULL)
  return(-2); /*failed opening infile*/
  fseek(infile,0L,SEEK_END);
  insize=ftell(infile);
  rewind(infile);
  plaintext=malloc(insize);
  ciphertext=malloc(2*insize);
  b64ctx=malloc(2*insize);
  ERR_load_crypto_strings();
  OpenSSL_add_all_algorithms();
  OPENSSL_no_config();
  if((rb=fread(plaintext,1,insize,infile))!=insize)
  return(-3); /*did not read the entire infile */ 
  ctsize=obencrypt (plaintext,insize,key,iv,ciphertext); 
  b64ctx=base64(ciphertext,ctsize);
  printf("input filename: %s\n",infilename);
  printf("input file size: %i\n",insize);
  printf("ciphertext size: %i\n",ctsize);
  printf("base64 encoded ciphertext: %zu : %zu whole lines\n",strlen(b64ctx),strlen(b64ctx)/65);
  printf("intermediate c generated filename: %s\n",outfilename);
  fwrite(includes,1,strlen(includes),outfile);
  sprintf(str,"int ctx_len=%i;\n",ctsize);
  fwrite(str,1,strlen(str),outfile);
  fwrite("unsigned char *crypted_script=",1,30,outfile);
  for (i=0;i<strlen(b64ctx)/65;i++)
  { fputc(34,outfile); 
    fwrite(b64ctx+(65*i),1,64,outfile); 
    fputc(92,outfile);
    fputc('n',outfile);
    fputc(34,outfile); 
    fputc(10,outfile); 
  }
  if((i*65)< strlen(b64ctx))
  { fputc(34,outfile);
    fwrite(b64ctx+(65*i),1,strlen(b64ctx)-(65*i),outfile);
    fputc(92,outfile);
    fputc('n',outfile); 
    fputc(34,outfile);
    fputc(10,outfile);
  }
  fwrite(";\n",1,2,outfile);
if(reusable)
{ printf("Creating reusable intermadiate c file\n");
  fwrite("unsigned char uuid[37]=",1,23,outfile);
  fputc(34,outfile);
  fwrite(uuid,1,strlen(uuid),outfile);
  fputc(34,outfile);
  fwrite(";\n",1,2,outfile);
  fwrite("unsigned char serial[17]=",1,25,outfile);
  fputc(34,outfile);
  fwrite(serial,1,strlen(serial),outfile);
  fputc(34,outfile);
  fwrite(";\n",1,2,outfile);
} else
{ printf("Creating non reusable binary\n"); 
  fwrite("unsigned char uuid[37]=",1,23,outfile);
  fputc(34,outfile);
  fputc(92,outfile); 
  fputc('0',outfile); 
  fputc(34,outfile);
  fwrite(";\n",1,2,outfile);
  fwrite("unsigned char serial[17]=",1,25,outfile);
  fputc(34,outfile);
  fputc(92,outfile);
  fputc('0',outfile);
  fputc(34,outfile);
  fwrite(";\n",1,2,outfile);
}
  fwrite(functions,1,strlen(functions),outfile);
  fwrite("\n",1,1,outfile);
  fwrite(main_body,1,strlen(main_body),outfile);
  fclose(outfile);
  fclose(infile);
  free(outfilename);
  free(plaintext);
  free(ciphertext);
  free(b64ctx);
  EVP_cleanup();
  ERR_free_strings();
  return(0);
}

int main(int argc, char *argv[])
{ char str[256]="\0";
  int rb,pid,status,len;
  char *ctx, *plaintext;
  int pipefd;
  char pipename[256]="\0";
  int i,j;
  static const char *copyright="Obfuscated Bash\n"
  "Copyright (C) 2017- Davide Rao: louigi600 (at) yahoo (dot) it\n"
  "\nThis program is free software; you can redistribute it and/or modify\n"
  "it under the terms of the GNU General Public License as published by\n"
  "the Free Software Foundation; either version 2 of the License, or\n"
  "(at your option) any later version provided that no poit of the\n"
  "AA License is violated.\n";
  if(strlen(uuid)==0) getuuid(uuid);  
  makekey(key,uuid);
  if(strlen(serial)==0) getserial(serial);
  makeiv(iv,serial);
  ctx=malloc(strlen(crypted_script));
  plaintext=malloc(strlen(crypted_script));
  ERR_load_crypto_strings();
  OpenSSL_add_all_algorithms();
  OPENSSL_no_config();
  ctx=unbase64(crypted_script,strlen(crypted_script));
  rb=decrypt(ctx,ctx_len,key,iv,plaintext);
  sprintf(pipename,"/tmp/%i",getpid());
  if(mkfifo(pipename, 0666)!=0)
  { unlink(pipename); /* assuming it failed because a file by that name exists */
    if(mkfifo(pipename, 0666)!=0)
    { printf("Aborting: could not create named pipe %s\n",pipename);
      exit(1);
    }
  }
  switch (pid=fork()) 
  { case -1: /* Handle fork error */
      printf("Error forking interpreter.\n");
      break;
    case 0:  /* Child - reads from named pipe */
       printf("\0");
       enum { MAX_ARGS = 64 };
       char *args[MAX_ARGS];
       char arg2[15]="\0";
       char **argp=args;
       args[0]="bash";
       args[1]="-c";
       sprintf(arg2,"source %s",pipename);
       argp[2]=arg2;
       argp[3]=argv[0];
       if (argc==1) args[4]=NULL;
       else
       { for(i=1;i<argc;i++)
         {  argp[i+3]=argv[i];
         }
         args[i+3]=NULL; 
       }
       fflush(stdout);
       execvp("bash",args);
       printf("Interpreter crashed.\n");
       break;
    default: /* Parent - writes to named pipe */
       pipefd=open(pipename, O_WRONLY);  
       write(pipefd,plaintext,rb);
       close(pipefd);
       break;
  }
  unlink(pipename);
  EVP_cleanup();
  ERR_free_strings(); 
  free(ctx);
  free(plaintext);
  waitpid(pid,&status,0);
  return(0);
}
