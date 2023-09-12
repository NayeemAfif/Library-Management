#!/bin/bash

# MySQL connection details
DB_HOST="localhost"
DB_USER="root"
DB_PASS="root"
DB_NAME="library"


message="Welcome to BIT Library"
whiptail --msgbox --title "Intro to Whiptail" "$message" 50 150 

# Function to display a message box using Whiptail
show_message() {
  whiptail --msgbox "$1" 50 150
}

# Function to show a menu using Whiptail and return the selected option
show_menu() {
  local title="$1"
  local prompt="$2"
  shift 2
  whiptail --title "$title" --menu "$prompt" 50 150 4 "$@" 3>&1 1>&2 2>&3
}

# function to list all books
list_all_books_in_library() {

    QUERY="SELECT * FROM books ;"

    DATA=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "$QUERY")

    if [[ -z "$DATA" ]]; then
        whiptail --msgbox "There are no books in the library." 50 150
        return
    fi

    COLUMNS=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "SHOW COLUMNS FROM books")
    # formatted_columns=$(echo -e "$COLUMNS" | awk '{ print $1 }' | sed ':a;N;$!ba;s/\n/  /g')
    formatted_columns=$(echo "$COLUMNS" | awk '{ printf "%-15s", $1 }')

    # formatted_data=$(echo -e "$DATA" | sed 's/\t/    /g')
    formatted_data=$(echo -e "$DATA" | awk -F '\t' '{ for (i=1; i<=NF; i++) printf "%-15s", $i; printf "\n" }')

    whiptail --msgbox "$formatted_columns\n$formatted_data" 50 150

}

# function to list borrowed books
list_borrowed_books() {

    QUERY="SELECT * FROM borr_books"

    DATA=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "$QUERY")

    if [[ -z "$DATA" ]]; then
        whiptail --msgbox "No books are being currently borrowred." 50 150
        return
    fi

    COLUMNS=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "SHOW COLUMNS FROM borr_books")
    formatted_columns=$(echo "$COLUMNS" | awk '{ printf "%-15s", $1 }')

    formatted_data=$(echo -e "$DATA" | awk -F '\t' '{ for (i=1; i<=NF; i++) printf "%-15s", $i; printf "\n" }')
    whiptail --msgbox "$formatted_columns\n$formatted_data" 50 150

}

# function to list available books
list_available_books() {

    QUERY="SELECT * FROM avail_books"

    DATA=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "$QUERY")

    if [[ -z "$DATA" ]]; then
        whiptail --msgbox "No books are currently available." 50 150
        return
    fi

    COLUMNS=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "SHOW COLUMNS FROM avail_books")
    formatted_columns=$(echo "$COLUMNS" | awk '{ printf "%-15s", $1 }')

    formatted_data=$(echo -e "$DATA" | awk -F '\t' '{ for (i=1; i<=NF; i++) printf "%-15s", $i; printf "\n" }')
    whiptail --msgbox "$formatted_columns\n$formatted_data" 50 150

}

#function to add a book to the database
add_a_book() {
    BID=$(whiptail --inputbox "Enter book ID:" 50 150 3>&1 1>&2 2>&3)
    B_NAME=$(whiptail --inputbox "Enter the book name:" 50 150 3>&1 1>&2 2>&3)
    A_NAME=$(whiptail --inputbox "Enter the author's name:" 50 150 3>&1 1>&2 2>&3) 

    ADD_QUERY_BOOKS=" insert into books values ($BID, '$B_NAME', '$A_NAME', 'Available'); "
    ADD_QUERY_AVAIL=" insert into avail_books values ($BID, '$B_NAME', '$A_NAME' ); "

    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$ADD_QUERY_BOOKS"
    
    #checking if the data was corretcly inserted
    if [ $? -eq 0 ]; then
        whiptail --msgbox "Database Updated." 50 150
    else
        whiptail --msgbox "Error occured while inserting the values." 50 150
        return
    fi    
    
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$ADD_QUERY_AVAIL"

}

#function to remove a book from the database
delete_a_book() {
    BID=$(whiptail --inputbox "Enter book ID:" 50 150 3>&1 1>&2 2>&3)
    DELETE_BOOKS=" delete from books where id=$BID ; "
    DELETE_BORR_BOOKS=" delete from borr_books where id=$BID ; "
    DELETE_AVAIL_BOOKS=" delete from avail_books where id=$BID ; "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$DELETE_BOOKS"
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$DELETE_AVAIL_BOOKS"
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$DELETE_BORR_BOOKS"
    whiptail --msgbox "Database Updated." 50 150
}

# function to search for a specific book 
search_for_a_specific_book() {
	BNAME=$(whiptail --inputbox "Enter book name:" 50 150 3>&1 1>&2 2>&3)  
    QUERY=" select * from books where book_name='$BNAME' "
    DATA=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "$QUERY")

    if [[ -z "$DATA" ]]; then
        whiptail --msgbox "No such book exists with that name." 50 150
        return
    fi

    COLUMNS=$(mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -N -e "SHOW COLUMNS FROM books")
    formatted_columns=$(echo "$COLUMNS" | awk '{ printf "%-15s", $1 }')

    formatted_data=$(echo -e "$DATA" | awk -F '\t' '{ for (i=1; i<=NF; i++) printf "%-15s", $i; printf "\n" }')
    whiptail --msgbox "$formatted_columns\n$formatted_data" 50 150

}

#function to borrow a book
borrow_a_book() {
    BID=$(whiptail --inputbox "Enter book ID:" 50 150 3>&1 1>&2 2>&3)
    BNAME=$(whiptail --inputbox "Enter book name:" 50 150 3>&1 1>&2 2>&3)
    BORRNAME=$(whiptail --inputbox "Enter book borrower's name:" 50 150 3>&1 1>&2 2>&3)
    PHONE=$(whiptail --inputbox "Enter borrower's phone number:" 50 150 3>&1 1>&2 2>&3)
    ISSUE_DATE=$(whiptail --inputbox "Enter the issue date:" 50 150 "$(date +%Y-%m-%d)" 3>&1 1>&2 2>&3)
    RETURN_DATE=$(whiptail --inputbox "Enter the date of return:" 50 150 "$(date +%Y-%m-%d)" 3>&1 1>&2 2>&3)

    UPDATE_BOOKS=" update books set availability='Borrowred' where id=$BID ; "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$UPDATE_BOOKS"

    ADD_BORR=" insert into borr_books values ($BID, '$BNAME', '$BORRNAME', $PHONE, '$ISSUE_DATE', '$RETURN_DATE'); "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$ADD_BORR"

    DELETE_AVAIL_BOOKS=" delete from avail_books where id=$BID ; "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$DELETE_AVAIL_BOOKS"

    whiptail --msgbox "The book has been issued." 50 150

}

#function to return a book
return_a_book() {
    BID=$(whiptail --inputbox "Enter book ID:" 50 150 3>&1 1>&2 2>&3)
    BNAME=$(whiptail --inputbox "Enter book name:" 50 150 3>&1 1>&2 2>&3)
    A_NAME=$(whiptail --inputbox "Enter the author's name:" 50 150 3>&1 1>&2 2>&3) 

    DELETE_BORR_BOOKS=" delete from borr_books where id=$BID ; "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$DELETE_BORR_BOOKS"

    UPDATE_BOOKS=" update books set availability='Available' where id=$BID ; "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$UPDATE_BOOKS"

    ADD_AVAIL=" insert into avail_books values ($BID, '$BNAME', '$A_NAME' ); "
    mysql -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" -e "$ADD_AVAIL"

    whiptail --msgbox "The book has been taken." 50 150

}

# Main menu
while true; do
  choice=$(show_menu "Library Management" "Select an option:" \
	"1" "List all books in the library" \
	"2" "Books Available" \
  "3" "Books Borrowed" \
  "4" "Add a book to the library" \
  "5" "Delete a book from the library" \
	"6" "Search for a specific book" \
  "7" "Borrow a book" \
  "8" "Return a book" \
  "9" "Exit"
  )

  case $choice in
	 1) list_all_books_in_library ;;
     2) list_available_books ;;
     3) list_borrowed_books ;;
     4) add_a_book ;;
     5) delete_a_book ;;
     6) search_for_a_specific_book ;;
     7) borrow_a_book ;;
     8) return_a_book ;; 	 
	 9) exit 0 ;;
    *)
    show_message "Invalid choice, please try again."
    ;;
  esac
done
