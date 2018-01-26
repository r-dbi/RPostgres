#ifndef RSQLite_workarounds_XPtr_h
#define RSQLite_workarounds_XPtr_h


#ifdef __CLION__

namespace Rcpp{

  template <
  typename T>
  class XPtr
  {
  public:
    explicit XPtr(SEXP x, SEXP tag = R_NilValue, SEXP prot = R_NilValue);
    explicit XPtr(T* p, bool set_delete_finalizer = true, SEXP tag = R_NilValue, SEXP prot = R_NilValue);
    XPtr( const XPtr& other );
    XPtr& operator=(const XPtr& other);

    inline T* get() const;

    typedef void (*unspecified_bool_type)();
    static void unspecified_bool_true();
    operator unspecified_bool_type() const;
    bool operator!() const;

    inline T* checked_get() const;

    T& operator*() const;

    T* operator->() const;

    void release();

    inline operator T*();

    void update(SEXP);
  };

} // namespace Rcpp

#endif // #ifdef __CLION__

#endif // #ifndef RSQLite_workarounds_XPtr_h
