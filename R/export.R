# Created with:
# methods::getGenerics(asNamespace("DBI")) %>%
#   grep("^db[A-Z]", ., value = TRUE) %>%
#   setdiff(c("dbCallProc", "dbListConnections", "dbSetDataMappings", "dbGetException")) %>%
#   paste0("#' @exportMethod ", ., "\nNULL\n", collapse = "\n") %>%
#   cat(file = "R/export.R")

#' @exportMethod dbBegin
NULL

#' @exportMethod dbBind
NULL

#' @exportMethod dbClearResult
NULL

#' @exportMethod dbColumnInfo
NULL

#' @exportMethod dbCommit
NULL

#' @exportMethod dbConnect
NULL

#' @exportMethod dbDataType
NULL

#' @exportMethod dbDisconnect
NULL

#' @exportMethod dbDriver
NULL

#' @exportMethod dbExecute
NULL

#' @exportMethod dbExistsTable
NULL

#' @exportMethod dbFetch
NULL

#' @exportMethod dbGetInfo
NULL

#' @exportMethod dbGetQuery
NULL

#' @exportMethod dbGetRowCount
NULL

#' @exportMethod dbGetRowsAffected
NULL

#' @exportMethod dbGetStatement
NULL

#' @exportMethod dbHasCompleted
NULL

#' @exportMethod dbIsValid
NULL

#' @exportMethod dbListFields
NULL

#' @exportMethod dbListObjects
NULL

#' @exportMethod dbListResults
NULL

#' @exportMethod dbListTables
NULL

#' @exportMethod dbQuoteIdentifier
NULL

#' @exportMethod dbQuoteLiteral
NULL

#' @exportMethod dbQuoteLiteral
NULL

#' @exportMethod dbQuoteString
NULL

#' @exportMethod dbReadTable
NULL

#' @exportMethod dbRemoveTable
NULL

#' @exportMethod dbRollback
NULL

#' @exportMethod dbSendQuery
NULL

#' @exportMethod dbSendStatement
NULL

#' @exportMethod dbUnloadDriver
NULL

#' @exportMethod dbWithTransaction
NULL

#' @exportMethod dbWriteTable
NULL
