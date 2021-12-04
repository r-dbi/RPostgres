# immediate with interrupts after notice

    Code
      out
    Output
      $code
      [1] 200
      
      $stdout
      [1] "<Rcpp::exception: Interrupted.>\n"
      
      $stderr
      [1] "NOTICE:  message_one"
      
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
      <Rcpp::exception: Interrupted.>
      
      $stdout
      [1] ""
      
      $stderr
      [1] ""
      
      $error
      NULL
      
      attr(,"class")
      [1] "callr_session_result"

