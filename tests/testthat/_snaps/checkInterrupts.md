# check_interrupts = TRUE interrupts immediately (#336)

    Code
      out
    Output
      $code
      [1] 200
      
      $message
      [1] "done callr-rs-result-ac0d53be20f45"
      
      $result
      NULL
      
      $stdout
      [1] ""
      
      $stderr
      [1] "Error in mycall(sym_setout, as.integer(fd), as.logical(drop)) : \n  Cannot reroute stdout (system error 9, Bad file descriptor) @client.c:180 (processx_set_std)\nCalls: tryCatch ... tryCatchList -> tryCatchOne -> <Anonymous> -> <Anonymous>\n"
      
      $error
      <callr_status_error: callr subprocess failed:>
       in process 
      -->
      <callr_remote_error in NULL:
       >
       in process 704753 
      
      attr(,"class")
      [1] "callr_session_result"

