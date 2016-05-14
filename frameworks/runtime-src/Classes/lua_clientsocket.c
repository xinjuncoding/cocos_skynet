
#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>

#define CACHE_SIZE 0x1000	

static int
lconnect(lua_State *L) {
	const char * addr = luaL_checkstring(L, 1);
	int port = luaL_checkinteger(L, 2);
    
    int flag = 0;
	int fd = socket(AF_INET,SOCK_STREAM,0);
    flag = fcntl(fd, F_GETFL, 0);
    if(fcntl(fd, F_SETFL, flag | O_NONBLOCK) < 0){
        close(fd);
        return luaL_error(L, "Connect %s %d failed, set nonblock faild!", addr, port);
    }
	struct sockaddr_in my_addr;
	my_addr.sin_addr.s_addr=inet_addr(addr);
	my_addr.sin_family=AF_INET;
	my_addr.sin_port=htons(port);
    int ret = connect(fd,(struct sockaddr *)&my_addr,sizeof(struct sockaddr_in));
	if (ret < 0 ){
        if(errno == EISCONN || errno == EAGAIN || errno == EINPROGRESS ){
            
        }
        else{
            close(fd);
            return luaL_error(L, "Connect %s %d %d failed", addr, port, errno);
        }
	}

	lua_pushinteger(L, fd);

	return 1;
}

static int
lslconnect(lua_State *L){
    int fd = luaL_checkinteger(L, 1);
    
    fd_set fds_red, fds_write;
    struct timeval tval;
    int selret = 0;
    tval.tv_sec = 0;
    tval.tv_usec = 0;

    FD_ZERO(&fds_red);
    FD_SET(fd, &fds_red);
        
    FD_ZERO(&fds_write);
    FD_SET(fd, &fds_write);

    int ret = 0;
    
    selret = select(fd + 1, &fds_red, &fds_write, NULL, &tval);
    if(selret < 0){
        if(errno == EINTR){
            ret = 1; // connecting
        }
        else{
            ret = -1; // connect faild
            close(fd);
        }
    }
    else if(selret == 0){
        ret = -2; // timeout
        close(fd);
    }
    else{
        if(FD_ISSET(fd, &fds_red) || FD_ISSET(fd, &fds_write)){
            int error = 0;
            int len = sizeof(error);
            int rc = getsockopt(fd, SOL_SOCKET, SO_ERROR, (void *) &error, &len);
            if(rc == -1){
                ret = -3; // connection closed!
                close(fd);
            }
            else if(error){
                ret = -1;
                close(fd);
            }
            else{
                ret = 0; // connect ok
            }
        }
        else{
            ret = 2; // no descriptor is ready
        }
    }
    
    lua_pushinteger(L, ret);

    return 1;
}

static int
lclose(lua_State *L) {
	int fd = luaL_checkinteger(L, 1);
	close(fd);

	return 0;
}

static void
block_send(lua_State *L, int fd, const char * buffer, int sz) {
	while(sz > 0) {
		int r = send(fd, buffer, sz, 0);
		if (r < 0) {
			if (errno == EAGAIN || errno == EINTR)
				continue;
            
            close(fd);
			luaL_error(L, "socket error: %s", strerror(errno));
		}
		buffer += r;
		sz -= r;
	}
}

/*
	integer fd
	string message
 */
static int
lsend(lua_State *L) {
	size_t sz = 0;
	int fd = luaL_checkinteger(L,1);
	const char * msg = luaL_checklstring(L, 2, &sz);

	block_send(L, fd, msg, (int)sz);

	return 0;
}

static int
lrecv(lua_State *L) {
	int fd = luaL_checkinteger(L,1);
    
    int ret = 0;
    int len = 0;
    char buffer[CACHE_SIZE];
    
    fd_set fds_red;
    struct timeval tval;
    int selret = 0;
    tval.tv_sec = 0;
    tval.tv_usec = 0;

    //we must clear fds for every loop, otherwise can not check the change of descriptor
    FD_ZERO(&fds_red);
    FD_SET(fd, &fds_red);

    selret = select(fd + 1, &fds_red, NULL, NULL, &tval);
    if(selret < 0){
        if(errno == EINTR){
            ret = 1;
        }
        else{
            // select faild!
            ret = -1;
            close(fd);
        }
    }
    else if(selret == 0){
        ret = 3; //select timeout, no descriptors can be read or written
    }
    else{
        
        if(FD_ISSET(fd, &fds_red)){
            len = recv(fd, buffer, CACHE_SIZE, 0) ;
            if(len < 0){
                if(errno == EAGAIN || errno == EWOULDBLOCK){
                    ret = 2;
                }
                else if(errno == EINTR ){
                    ret = 1;
                }
                else{
                    // recv data error is
                    ret = -2;
                    close(fd);
                }
            }
            else if(len == 0){
                // socket is closed
                ret = -1;
                close(fd);
            }
            else{
                ret = 0; // normal recv
            }
        }
        else {
            ret = -1;
            close(fd);
        }
    }

    lua_pushinteger(L, ret);
    if(ret == 0)
        lua_pushlstring(L, buffer, len);
    else
        lua_pushliteral(L, "");
    
	return 2;
}

int
luaopen_clientsocket(lua_State *L) {
#ifdef luaL_checkversion
    luaL_checkversion(L);
#endif
    luaL_Reg l[] = {
        { "connect", lconnect },
        { "slcon", lslconnect },
        { "recv", lrecv },
        { "send", lsend },
        { "close", lclose },
        { NULL, NULL },
    };
    luaL_openlib(L, "clientsocket", l, 0);

	return 1;
}
