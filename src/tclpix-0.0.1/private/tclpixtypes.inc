# Based on Mark Janssen's tclstubs package, file modified to suit my needs.
# (https://github.com/mpcjanssen/tclstubs-nimble) (MIT licence)

{.deadCodeElim: on.}

const 
  DESTROYED* = 0xDEADDEAD
  OK* = 0
  ERROR* = 1
  RETURN* = 2
  BREAK* = 3
  CONTINUE* = 4
  RESULT_SIZE* = 200
  MAX_ARGV* = 0x00007FFF
  VERSION_MAJOR* = 0
  VERSION_MINOR* = 0
  NO_EVAL* = 0x00010000
  EVAL_GLOBAL* = 0x00020000 # Flag values passed to variable-related proc
  GLOBAL_ONLY* = 1
  NAMESPACE_ONLY* = 2
  APPEND_VALUE* = 4
  LIST_ELEMENT* = 8
  TRACE_READS* = 0x00000010
  TRACE_WRITES* = 0x00000020
  TRACE_UNSETS* = 0x00000040
  TRACE_DESTROYED* = 0x00000080
  INTERP_DESTROYED* = 0x00000100
  LEAVE_ERR_MSG* = 0x00000200
  PARSE_PART1* = 0x00000400 # Types for linked variables: *
  LINK_INT* = 1
  LINK_DOUBLE* = 2
  LINK_BOOLEAN* = 3
  LINK_STRING* = 4
  LINK_READ_ONLY* = 0x00000080
  SMALL_HASH_TABLE* = 4   # Hash Table *
  STRING_KEYS* = 0
  ONE_WORD_KEYS* = 1      # Const/enums Tcl_QueuePosition *
                          
  QUEUE_TAIL* = 0
  QUEUE_HEAD* = 1
  QUEUE_MARK* = 2         # Tcl_QueuePosition;
                          # Event Flags
  DONT_WAIT* = 1 shl 1
  WINDOW_EVENTS* = 1 shl 2
  FILE_EVENTS* = 1 shl 3
  TIMER_EVENTS* = 1 shl 4
  IDLE_EVENTS* = 1 shl 5  # WAS 0x10 ???? *
  ALL_EVENTS* = not DONT_WAIT
  VOLATILE* = 1
  STATIC* = 0
  DYNAMIC* = 3            # Channel
  STDIN* = 1 shl 1
  STDOUT* = 1 shl 2
  STDERR* = 1 shl 3
  ENFORCE_MODE* = 1 shl 4
  READABLE* = 1 shl 1
  WRITABLE* = 1 shl 2
  EXCEPTION* = 1 shl 3    # POSIX *
  EPERM* = 1 # Operation not permitted; only the owner of the file (or other
             # resource) or processes with special privileges can perform the
             # operation.
             #
  ENOENT* = 2 # No such file or directory.  This is a "file doesn't exist" error
              # for ordinary files that are referenced in contexts where they are
              # expected to already exist.
              #
  ESRCH* = 3                  # No process matches the specified process ID. *
  EINTR* = 4 # Interrupted function call; an asynchronous signal occurred and
             # prevented completion of the call.  When this happens, you should
             # try the call again.
             #
  EIO* = 5                    # Input/output error; usually used for physical read or write errors. *
  ENXIO* = 6 # No such device or address.  The system tried to use the device
             # represented by a file you specified, and it couldn't find the
             # device.  This can mean that the device file was installed
             # incorrectly, or that the physical device is missing or not
             # correctly attached to the computer.
             #
  E2BIG* = 7 # Argument list too long; used when the arguments passed to a new
             # program being executed with one of the `exec' functions (*note
             # Executing a File::.) occupy too much memory space.  This condition
             # never arises in the GNU system.
             #
  ENOEXEC* = 8 # Invalid executable file format.  This condition is detected by the
               # `exec' functions; see *Note Executing a File::.
               #
  EBADF* = 9 # Bad file descriptor; for example, I/O on a descriptor that has been
             # closed or reading from a descriptor open only for writing (or vice
             # versa).
             #
  ECHILD* = 10 # There are no child processes.  This error happens on operations
               # that are supposed to manipulate child processes, when there aren't
               # any processes to manipulate.
               #
  EDEADLK* = 11 # Deadlock avoided; allocating a system resource would have resulted
                # in a deadlock situation.  The system does not guarantee that it
                # will notice all such situations.  This error means you got lucky
                # and the system noticed; it might just hang.  *Note File Locks::,
                # for an example.
                #
  ENOMEM* = 12 # No memory available.  The system cannot allocate more virtual
               # memory because its capacity is full.
               #
  EACCES* = 13 # Permission denied; the file permissions do not allow the attempted
               # operation.
               #
  EFAULT* = 14 # Bad address; an invalid pointer was detected.  In the GNU system,
               # this error never happens; you get a signal instead.
               #
  ENOTBLK* = 15 # A file that isn't a block special file was given in a situation
                # that requires one.  For example, trying to mount an ordinary file
                # as a file system in Unix gives this error.
                #
  EBUSY* = 16 # Resource busy; a system resource that can't be shared is already
              # in use.  For example, if you try to delete a file that is the root
              # of a currently mounted filesystem, you get this error.
              #
  EEXIST* = 17 # File exists; an existing file was specified in a context where it
               # only makes sense to specify a new file.
               #
  EXDEV* = 18 # An attempt to make an improper link across file systems was
              # detected.  This happens not only when you use `link' (*note Hard
              # Links::.) but also when you rename a file with `rename' (*note
              # Renaming Files::.).
              #
  ENODEV* = 19 # The wrong type of device was given to a function that expects a
               # particular sort of device.
               #
  ENOTDIR* = 20 # A file that isn't a directory was specified when a directory is
                # required.
                #
  EISDIR* = 21 # File is a directory; you cannot open a directory for writing, or
               # create or remove hard links to it.
               #
  EINVAL* = 22 # Invalid argument.  This is used to indicate various kinds of
               # problems with passing the wrong argument to a library function.
               #
  EMFILE* = 24 # The current process has too many files open and can't open any
               # more.  Duplicate descriptors do count toward this limit.
               #
               # In BSD and GNU, the number of open files is controlled by a
               # resource limit that can usually be increased.  If you get this
               # error, you might want to increase the `RLIMIT_NOFILE' limit or
               # make it unlimited; *note Limits on Resources::..
               #
  ENFILE* = 23 # There are too many distinct file openings in the entire system.
               # Note that any number of linked channels count as just one file
               # opening; see *Note Linked Channels::.  This error never occurs in
               # the GNU system.
               #
  ENOTTY* = 25 # Inappropriate I/O control operation, such as trying to set terminal
               # modes on an ordinary file.
               #
  ETXTBSY* = 26 # An attempt to execute a file that is currently open for writing, or
                # write to a file that is currently being executed.  Often using a
                # debugger to run a program is considered having it open for writing
                # and will cause this error.  (The name stands for "text file
                # busy".)  This is not an error in the GNU system; the text is
                # copied as necessary.
                #
  EFBIG* = 27 # File too big; the size of a file would be larger than allowed by
              # the system.
              #
  ENOSPC* = 28 # No space left on device; write operation on a file failed because
               # the disk is full.
               #
  ESPIPE* = 29                # Invalid seek operation (such as on a pipe).  *
  EROFS* = 30                 # An attempt was made to modify something on a read-only file system.  *
  EMLINK* = 31 # Too many links; the link count of a single file would become too
               # large.  `rename' can cause this error if the file being renamed
               # already has as many links as it can take (*note Renaming Files::.).
               #
  EPIPE* = 32 # Broken pipe; there is no process reading from the other end of a
              # pipe.  Every library function that returns this error code also
              # generates a `SIGPIPE' signal; this signal terminates the program
              # if not handled or blocked.  Thus, your program will never actually
              # see `EPIPE' unless it has handled or blocked `SIGPIPE'.
              #
  EDOM* = 33 # Domain error; used by mathematical functions when an argument
             # value does not fall into the domain over which the function is
             # defined.
             #
  ERANGE* = 34 # Range error; used by mathematical functions when the result value
               # is not representable because of overflow or underflow.
               #
  EAGAIN* = 35 # Resource temporarily unavailable; the call might work if you try
               # again later.  The macro `EWOULDBLOCK' is another name for `EAGAIN';
               # they are always the same in the GNU C library.
               #
  EWOULDBLOCK* = EAGAIN # In the GNU C library, this is another name for `EAGAIN' (above).
                        # The values are always the same, on every operating system.
                        # C libraries in many older Unix systems have `EWOULDBLOCK' as a
                        # separate error code.
                        #
  EINPROGRESS* = 36 # An operation that cannot complete immediately was initiated on an
                    # object that has non-blocking mode selected.  Some functions that
                    # must always block (such as `connect'; *note Connecting::.) never
                    # return `EAGAIN'.  Instead, they return `EINPROGRESS' to indicate
                    # that the operation has begun and will take some time.  Attempts to
                    # manipulate the object before the call completes return `EALREADY'.
                    # You can use the `select' function to find out when the pending
                    # operation has completed; *note Waiting for I/O::..
                    #
  EALREADY* = 37 # An operation is already in progress on an object that has
                 # non-blocking mode selected.
                 #
  ENOTSOCK* = 38              # A file that isn't a socket was specified when a socket is required.  *
  EDESTADDRREQ* = 39 # No default destination address was set for the socket.  You get
                     # this error when you try to transmit data over a connectionless
                     # socket, without first specifying a destination for the data with
                     # `connect'.
                     #
  EMSGSIZE* = 40 # The size of a message sent on a socket was larger than the
                 # supported maximum size.
                 #
  EPROTOTYPE* = 41 # The socket type does not support the requested communications
                   # protocol.
                   #
  ENOPROTOOPT* = 42 # You specified a socket option that doesn't make sense for the
                    # particular protocol being used by the socket.  *Note Socket
                    # Options::.
                    #
  EPROTONOSUPPORT* = 43 # The socket domain does not support the requested communications
                        # protocol (perhaps because the requested protocol is completely
                        # invalid.) *Note Creating a Socket::.
                        #
  ESOCKTNOSUPPORT* = 44       # The socket type is not supported.  *
  EOPNOTSUPP* = 45 # The operation you requested is not supported.  Some socket
                   # functions don't make sense for all types of sockets, and others
                   # may not be implemented for all communications protocols.  In the
                   # GNU system, this error can happen for many calls when the object
                   # does not support the particular operation; it is a generic
                   # indication that the server knows nothing to do for that call.
                   #
  EPFNOSUPPORT* = 46 # The socket communications protocol family you requested is not
                     # supported.
                     #
  EAFNOSUPPORT* = 47 # The address family specified for a socket is not supported; it is
                     # inconsistent with the protocol being used on the socket.  *Note
                     # Sockets::.
                     #
  EADDRINUSE* = 48 # The requested socket address is already in use.  *Note Socket
                   # Addresses::.
                   #
  EADDRNOTAVAIL* = 49 # The requested socket address is not available; for example, you
                      # tried to give a socket a name that doesn't match the local host
                      # name.  *Note Socket Addresses::.
                      #
  ENETDOWN* = 50              # A socket operation failed because the network was down.  *
  ENETUNREACH* = 51 # A socket operation failed because the subnet containing the remote
                    # host was unreachable.
                    #
  ENETRESET* = 52             # A network connection was reset because the remote host crashed.  *
  ECONNABORTED* = 53          # A network connection was aborted locally. *
  ECONNRESET* = 54 # A network connection was closed for reasons outside the control of
                   # the local host, such as by the remote machine rebooting or an
                   # unrecoverable protocol violation.
                   #
  ENOBUFS* = 55 # The kernel's buffers for I/O operations are all in use.  In GNU,
                # this error is always synonymous with `ENOMEM'; you may get one or
                # the other from network operations.
                #
  EISCONN* = 56 # You tried to connect a socket that is already connected.  *Note
                # Connecting::.
                #
  ENOTCONN* = 57 # The socket is not connected to anything.  You get this error when
                 # you try to transmit data over a socket, without first specifying a
                 # destination for the data.  For a connectionless socket (for
                 # datagram protocols, such as UDP), you get `EDESTADDRREQ' instead.
                 #
  ESHUTDOWN* = 58             # The socket has already been shut down.  *
  ETOOMANYREFS* = 59          # ???  *
  ETIMEDOUT* = 60 # A socket operation with a specified timeout received no response
                  # during the timeout period.
                  #
  ECONNREFUSED* = 61 # A remote host refused to allow the network connection (typically
                     # because it is not running the requested service).
                     #
  ELOOP* = 62 # Too many levels of symbolic links were encountered in looking up a
              # file name.  This often indicates a cycle of symbolic links.
              #
  ENAMETOOLONG* = 63 # Filename too long (longer than `PATH_MAX'; *note Limits for
                     # Files::.) or host name too long (in `gethostname' or
                     # `sethostname'; *note Host Identification::.).
                     #
  EHOSTDOWN* = 64             # The remote host for a requested network connection is down.  *
  EHOSTUNREACH* = 65 # The remote host for a requested network connection is not
                     # reachable.
                     #
  ENOTEMPTY* = 66 # Directory not empty, where an empty directory was expected.
                  # Typically, this error occurs when you are trying to delete a
                  # directory.
                  #
  EPROCLIM* = 67 # This means that the per-user limit on new process would be
                 # exceeded by an attempted `fork'.  *Note Limits on Resources::, for
                 # details on the `RLIMIT_NPROC' limit.
                 #
  EUSERS* = 68                # The file quota system is confused because there are too many users.  *
  EDQUOT* = 69                # The user's disk quota was exceeded.  *
  ESTALE* = 70 # Stale NFS file handle.  This indicates an internal confusion in
               # the NFS system which is due to file system rearrangements on the
               # server host.  Repairing this condition usually requires unmounting
               # and remounting the NFS file system on the local host.
               #
  EREMOTE* = 71 # An attempt was made to NFS-mount a remote file system with a file
                # name that already specifies an NFS-mounted file.  (This is an
                # error on some operating systems, but we expect it to work properly
                # on the GNU system, making this error code impossible.)
                #
  EBADRPC* = 72               # ???  *
  ERPCMISMATCH* = 73          # ???  *
  EPROGUNAVAIL* = 74          # ???  *
  EPROGMISMATCH* = 75         # ???  *
  EPROCUNAVAIL* = 76          # ???  *
  ENOLCK* = 77 # No locks available.  This is used by the file locking facilities;
               # see *Note File Locks::.  This error is never generated by the GNU
               # system, but it can result from an operation to an NFS server
               # running another operating system.
               #
  ENOSYS* = 78 # Function not implemented.  Some functions have commands or options
               # defined that might not be supported in all implementations, and
               # this is the kind of error you get if you request them and they are
               # not supported.
               #
  EFTYPE* = 79 # Inappropriate file type or format.  The file was the wrong type
               # for the operation, or a data file had the wrong format.
               # On some systems `chmod' returns this error if you try to set the
               # sticky bit on a non-directory file; *note Setting Permissions::..
               #

type 
  TArgv* = cstringArray
  TClientData* = pointer
  TFreeProc* = proc (theBlock: pointer){.cdecl.}
  PInterp* = ptr TInterp
  TInterp*{.final.} = object  #  Event Definitions
    result*: cstring # Do not access this directly. Use
                     # Tcl_GetStringResult since result
                     # may be pointing to an object
    freeProc*: TFreeProc
    errorLine*: int

  TEventSetupProc* = proc (clientData: TClientData, flags: int){.cdecl.}
  TEventCheckProc* = TEventSetupProc
  PEvent* = ptr TEvent
  TEventProc* = proc (evPtr: PEvent, flags: int): int{.cdecl.}
  TEvent*{.final.} = object 
    prc*: TEventProc
    nextPtr*: PEvent
    ClientData*: RootObj      # ClientData is just pointer.*
  
  PTime* = ptr TTime
  TTime*{.final.} = object 
    sec*: int32               # Seconds. * 
    usec*: int32              # Microseconds. * 
  
  TTimerToken* = pointer
  PInteger* = ptr int
  PHashTable* = ptr THashTable
  PHashEntry* = ptr THashEntry
  PPHashEntry* = ptr PHashEntry
  THashEntry*{.final.} = object 
    nextPtr*: PHashEntry
    tablePtr*: PHashTable
    bucketPtr*: PPHashEntry
    clientData*: TClientData
    key*: cstring

  THashFindProc* = proc (tablePtr: PHashTable, key: cstring): PHashEntry{.
      cdecl.}
  THashCreateProc* = proc (tablePtr: PHashTable, key: cstring, 
                              newPtr: PInteger): PHashEntry{.cdecl.}
  THashTable*{.final.} = object 
    buckets*: PPHashEntry
    staticBuckets*: array[0..SMALL_HASH_TABLE - 1, PHashEntry]
    numBuckets*: int
    numEntries*: int
    rebuildSize*: int
    downShift*: int
    mask*: int
    keyType*: int
    findProc*: THashFindProc
    createProc*: THashCreateProc

  PHashSearch* = ptr THashSearch
  THashSearch*{.final.} = object 
    tablePtr*: PHashTable
    nextIndex*: int
    nextEntryPtr*: PHashEntry

  TAppInitProc* = proc (interp: PInterp): int{.cdecl.}
  TPackageInitProc* = proc (interp: PInterp): int{.cdecl.}
  TCmdProc* = proc (clientData: TClientData, interp: PInterp, argc: int, 
                    argv: TArgv): int{.cdecl.}
  TVarTraceProc* = proc (clientData: TClientData, interp: PInterp, 
                         varName: cstring, elemName: cstring, flags: int): cstring{.
      cdecl.}
  TInterpDeleteProc* = proc (clientData: TClientData, interp: PInterp){.cdecl.}
  TCmdDeleteProc* = proc (clientData: TClientData){.cdecl.}
  TNamespaceDeleteProc* = proc (clientData: TClientData){.cdecl.}

const 
  DSTRING_STATIC_SIZE* = 200

type 
  PDString* = ptr TDString
  TDString*{.final.} = object 
    str*: cstring
    len*: int
    spaceAvl*: int
    staticSpace*: array[0..DSTRING_STATIC_SIZE - 1, char]

  PChannel* = ptr TChannel
  TChannel*{.final.} = object 
  TDriverBlockModeProc* = proc (instanceData: TClientData, mode: int): int{.
      cdecl.}
  TDriverCloseProc* = proc (instanceData: TClientData, interp: PInterp): int{.
      cdecl.}
  TDriverInputProc* = proc (instanceData: TClientData, buf: cstring, 
                            toRead: int, errorCodePtr: PInteger): int{.cdecl.}
  TDriverOutputProc* = proc (instanceData: TClientData, buf: cstring, 
                             toWrite: int, errorCodePtr: PInteger): int{.cdecl.}
  TDriverSeekProc* = proc (instanceData: TClientData, offset: int32, 
                           mode: int, errorCodePtr: PInteger): int{.cdecl.}
  TDriverSetOptionProc* = proc (instanceData: TClientData, interp: PInterp, 
                                optionName: cstring, value: cstring): int{.cdecl.}
  TDriverGetOptionProc* = proc (instanceData: TClientData, interp: PInterp, 
                                optionName: cstring, dsPtr: PDString): int{.
      cdecl.}
  TDriverWatchProc* = proc (instanceData: TClientData, mask: int){.cdecl.}
  TDriverGetHandleProc* = proc (instanceData: TClientData, direction: int, 
                                handlePtr: var TClientData): int{.cdecl.}
  PChannelType* = ptr TChannelType
  TChannelType*{.final.} = object 
    typeName*: cstring
    blockModeProc*: TDriverBlockModeProc
    closeProc*: TDriverCloseProc
    inputProc*: TDriverInputProc
    ouputProc*: TDriverOutputProc
    seekProc*: TDriverSeekProc
    setOptionProc*: TDriverSetOptionProc
    getOptionProc*: TDriverGetOptionProc
    watchProc*: TDriverWatchProc
    getHandleProc*: TDriverGetHandleProc

  TChannelProc* = proc (clientData: TClientData, mask: int){.cdecl.}
  PObj* = ptr TObj
  PPObj* = ptr UncheckedArray[PObj]
  TObj*{.final.} = object 
    refCount*: int            # ...
  
  TObjCmdProc* = proc (clientData: TClientData, interp: PInterp, objc: int, 
                       PPObj: PPObj): int{.cdecl.}
  PNamespace* = ptr TNamespace
  TNamespace*{.final.} = object 
    name*: cstring
    fullName*: cstring
    clientData*: TClientData
    deleteProc*: TNamespaceDeleteProc
    parentPtr*: PNamespace

  PCallFrame* = ptr TCallFrame
  TCallFrame*{.final.} = object 
    nsPtr*: PNamespace
    dummy1*: int
    dummy2*: int
    dummy3*: cstring
    dummy4*: cstring
    dummy5*: cstring
    dummy6*: int
    dummy7*: cstring
    dummy8*: cstring
    dummy9*: int
    dummy10*: cstring

  PCmdInfo* = ptr TCmdInfo
  TCmdInfo*{.final.} = object 
    isNativeObjectProc*: int
    objProc*: TObjCmdProc
    objClientData*: TClientData
    prc*: TCmdProc
    clientData*: TClientData
    deleteProc*: TCmdDeleteProc
    deleteData*: TClientData
    namespacePtr*: PNamespace

  pCommand* = ptr TCommand
  TCommand*{.final.} = object     #       hPtr            : pTcl_HashEntry;
                                  #        nsPtr           : pTcl_Namespace;
                                  #        refCount        : integer;
                                  #        isCmdEpoch      : integer;
                                  #        compileProc     : pointer;
                                  #        objProc         : pointer;
                                  #        objClientData   : Tcl_ClientData;
                                  #        proc            : pointer;
                                  #        clientData      : Tcl_ClientData;
                                  #        deleteProc      : TTclCmdDeleteProc;
                                  #        deleteData      : Tcl_ClientData;
                                  #        deleted         : integer;
                                  #        importRefPtr    : pointer;
                                  #

type 
  TPanicProc* = proc (fmt, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8: cstring){.
      cdecl.}                 # 1/15/97 orig. Tcl style
  TClientDataProc* = proc (clientData: TClientData){.cdecl.}
  TIdleProc* = proc (clientData: TClientData){.cdecl.}
  TTimerProc* = TIdleProc
  TCreateCloseHandler* = proc (channel: PChannel, prc: TClientDataProc, 
                               clientData: TClientData){.cdecl.}
  TDeleteCloseHandler* = TCreateCloseHandler
  TEventDeleteProc* = proc (evPtr: PEvent, clientData: TClientData): int{.
      cdecl.}

  TFileProc* = proc(clientData: TClientData, mask: cint) {.cdecl.}
  PFileProc* = ptr TFileProc

  # FIXME add these types
  PObjType* = pointer 
  PAsyncProc* = pointer 
  PIdleProc* = pointer 
  PChannelProc* = pointer 
  PCloseProc* = pointer 
  PCmdProc* = pointer 
  PCmdDeleteProc* = pointer 
  AsyncHandler* = pointer 
  PInterpDeleteProc* = pointer 
  Channel* = pointer 
  Command* = pointer
  PEventSetupProc* = pointer  
  PEventCheckProc* = pointer
  PEventDeleteProc* = pointer
  PExitProc* = pointer
  PValueType* = pointer
  PMathProc* = pointer
  PObjCmdProc* = pointer
  PTimerProc* = pointer
  PCmdTraceProc* = pointer
  TimerToken* = pointer
  Trace* = pointer
  PPid* = pointer
  PFreeProc* = pointer
  PClientData* = ptr TClientData
  PathType* = pointer
  PTcpAcceptProc* = pointer
  QueuePosition* = pointer
  RegExp* = pointer
  PPanicProc* = pointer
  PPackageInitProc* = pointer
  PVarTraceProc* = pointer
  Pid* = pointer
  PMainLoopProc* = pointer
  PEncodingType* = pointer
  Encoding* = pointer
  PSavedResult* = pointer
  PEncodingState* = pointer
  ThreadId* = pointer
  PThreadDataKey* = pointer
  PMutex* = pointer
  UniChar* = pointer
  PUniChar* = pointer
  PCondition* = pointer
  PToken* = pointer
  PParse* = pointer
  Pstat* = pointer
  PRegExpInfo* = pointer
  PNotifierProcs* = pointer
  PThreadId* = pointer
  PThreadCreateProc* = pointer
  ChannelTypeVersion* = pointer
  PDriverBlockModeProc* = pointer
  PDriverCloseProc* = pointer
  PDriverClose2Proc* = pointer
  PDriverInputProc* = pointer
  PDriverOutputProc* = pointer
  PDriverSeekProc* = pointer
  PDriverSetOptionProc* = pointer
  PDriverGetOptionProc* = pointer
  PDriverGetHandleProc* = pointer
  PDriverWatchProc* = pointer
  PDriverFlushProc* = pointer
  PDriverHandlerProc* = pointer
  PHashKeyType* = pointer
  PCommandTraceProc* = pointer
  PLoadHandle* = pointer
  PFSUnloadFileProc* = pointer
  PGlobTypeData* = pointer
  PStatBuf* = pointer
  PFileSystem* = pointer
  PCmdObjTraceProc* = pointer
  PCmdObjTraceDeleteProc* = pointer
  WideInt* = pointer
  PWideInt* = ptr WideInt
  PDriverWideSeekProc = pointer
  PDictSearch = pointer
  PConfig = pointer
  PNamespaceDeleteProc = pointer
  PLimitHandlerProc = pointer
  PLimitHandlerDeleteProc = pointer
  InterpState = pointer
  PGetTimeProc = pointer
  PScaleTimeProc = pointer
  PDriverThreadActionProc = pointer
  PDriverTruncateProc = pointer
  PEncoding = pointer
  PNRPostProc = pointer
  WideUInt = pointer
  PArgvInfo = pointer
  PZLibStream = ptr ZLibStream
  ZLibStream = pointer
  Pcstring = ptr cstring
  LoadHandle = pointer