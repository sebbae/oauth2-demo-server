package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	gh "github.com/google/go-github/github"
	"github.com/gorilla/mux"
	"github.com/gorilla/sessions"
	"github.com/urfave/negroni"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/github"
)

// Change this to a secure randing string!
// See http://www.gorillatoolkit.org/pkg/sessions#NewCookieStore for details
var Store = sessions.NewCookieStore([]byte("abcdef123456789abcdef123456789abcdef123456789abcdef123456789"))

var (
	conf = &oauth2.Config{
		ClientID:     "__CHANGE_TO_CLIENT_ID__",
		ClientSecret: "__CHANGE_TO_CLIENT_SECRET__",
		Scopes:       []string{"user:email"},
		Endpoint:     github.Endpoint,
	}
)

type Handler func(w http.ResponseWriter, r *http.Request)

func main() {
	r := mux.NewRouter().StrictSlash(false)
	r.HandleFunc("/home", GenericHandler("Home Page"))

	public := r.PathPrefix("/public").Subrouter()
	public.HandleFunc("/page0", GenericHandler("Page 0"))

	protected := r.PathPrefix("/protected").Subrouter()
	protected.HandleFunc("/page1", GenericHandler("Page 1"))
	protected.HandleFunc("/page2", GenericHandler("Page 2"))

	api := r.PathPrefix("/auth").Subrouter()
	api.HandleFunc("/login", LoginHandler)
	api.HandleFunc("/callback", CallbackHandler)
	api.HandleFunc("/logout", LogoutHandler)

	mux1 := http.NewServeMux()
	mux1.Handle("/protected/", negroni.New(
		negroni.HandlerFunc(AuthMiddleware),
		negroni.Wrap(r),
	))

	mux1.Handle("/public/", negroni.New(
		negroni.HandlerFunc(LoggingMiddleware),
		negroni.Wrap(r),
	))

	mux1.Handle("/auth/", negroni.New(
		negroni.HandlerFunc(LoggingMiddleware),
		negroni.Wrap(r),
	))

	n := negroni.Classic()
	n.UseHandler(mux1)
	http.ListenAndServe(":3000", n)
}

func GenericHandler(s string) Handler {
	return func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, s)
	}
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	url := conf.AuthCodeURL("state", oauth2.AccessTypeOnline)
	http.Redirect(w, r, url, http.StatusFound)
}

func LogoutHandler(w http.ResponseWriter, r *http.Request) {
	session, _ := Store.Get(r, "authtest")
	delete(session.Values, "user")
	session.Options.MaxAge = -1
	_ = session.Save(r, w)
	w.WriteHeader(http.StatusCreated)
}

func CallbackHandler(w http.ResponseWriter, r *http.Request) {
	code := r.FormValue("code")
	log.Println("Received oauth code:", code)

	token, err := conf.Exchange(oauth2.NoContext, code)
	if err != nil {
		log.Println("oauthConf.Exchange() failed with", err)
		http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
		return
	}

	oauthClient := conf.Client(oauth2.NoContext, token)
	client := gh.NewClient(oauthClient)
	ctx := context.Background()
	user, _, err := client.Users.Get(ctx, "")

	if err != nil {
		log.Println("github user fetch failed", err)
		http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
		return
	}

	session, err := Store.Get(r, "authtest")
	session.Values["user"] = *user.Login
	session.Save(r, w)
	http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
}

func AuthMiddleware(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	log.Println("AuthMiddleware")
	session, err := Store.Get(r, "authtest")

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Println(session.Values["user"])

	if session.Values["user"] == nil {
		log.Println("Redirect user")
		http.Redirect(w, r, "/auth/login", 301)
	} else {
		next(w, r)
	}
}

func LoggingMiddleware(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	log.Println("LoggingMiddleware")
	next(w, r)
}
