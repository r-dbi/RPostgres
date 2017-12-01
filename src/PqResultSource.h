#ifndef RPOSTGRES_PQRESULTSOURCE_H
#define RPOSTGRES_PQRESULTSOURCE_H

class PqResultSource {
public:
  PqResultSource();
  virtual ~PqResultSource();

public:
  virtual PGresult* get_result() = 0;
};

#endif //RPOSTGRES_PQRESULTSOURCE_H
