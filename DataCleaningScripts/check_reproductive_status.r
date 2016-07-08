# This function checks sexual characteristics against M/F designation in raw entered rodent data

male_female_check = function(ws) {
  
  # remove entries with missing M/F designation from error check
  ws1 = subset(ws,!is.na(sex))
  
  issues = vector()
  for (n in 1:length(ws1$sex)) {
    if (ws1$sex[n] == 'F'){
      if (!is.na(ws1$testes[n])) {
        issues = append(issues,n+1)
      }
    }
    else {if (ws1$sex[n] == 'M'){
      if (!is.na(ws1$vagina[n]) || !is.na(ws1$pregnant[n]) || !is.na(ws1$nipples[n]) || !is.na(ws1$lactation[n])){
        issues = append(issues,row.names(ws1)[n+1])
      }
    }
    }}
  print(paste('check M/F:',issues))
}
