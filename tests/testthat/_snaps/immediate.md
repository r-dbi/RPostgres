# immediate with interrupts after notice

    Code
      out
    Output
      $code
      [1] 200
      
      $stdout
      [1] ""
      
      $stderr
      [1] "NOTICE:  message_one\n"
      
      $error
      NULL
      
      attr(,"class")
      [1] "callr_session_result"

# immediate with interrupts before notice

    Code
      out
    Output
      $code
      [1] 200
      
      $result
      <Rcpp::exception: Failed to fetch row: ERROR:  canceling statement due to user request
      >
      
      $stdout
      [1] ""
      
      $stderr
      [1] ""
      
      $error
      NULL
      
      attr(,"class")
      [1] "callr_session_result"

