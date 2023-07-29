package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"regexp"
	"strings"
	"time"
)

var trimVariable = [5]string{`displayName: `, `sAMAccountName: `,
	`memberOf: CN=`, `mobile: `, `mail: `}
var department = []string{}
var userVariable = []string{}
var users = make(map[int][]string)
var letters = []rune("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

func main() {
	backupFile, err := ioutil.ReadFile("/home/user/Documents/output_file.ldif")
	checkError(err)
	//userTemplate, err := ioutil.ReadFile("/home/user/Documents/templateUser")
	checkError(err)
	//departamentTemplate, err := ioutil.ReadFile("/home/user/Documents/templateDepartament")
	checkError(err)
	//fmt.Println(departamentTemplate, userTemplate)
	paragraph := strings.Split(string(backupFile), "\n\r\n")
	for i := range paragraph {
		if i > 0 {
			rand.Seed(time.Now().UnixNano())
			userVariable = append(userVariable, "test")
			userVariable = append(userVariable, fmt.Sprintln(2500+i))
			userVariable = append(userVariable, fmt.
				Sprintln(randSeq(8)+"-"+randSeq(4)+"-"+randSeq(4)+"-"+randSeq(12)))
			users[i] = userVariable
			userVariable = nil
		}
		currentParagraph := paragraph[i]
		grepVariables(currentParagraph)
	}
	fmt.Printf("%v", department)
	//remakeBackup()
	remakeDepartment()
}

func grepVariables(currentParagraph string) {
breakDown:
	for i := range trimVariable {
		searchVariable := trimVariable[i] + ".+"
		if i == 2 {
			searchVariable = `memberOf: CN=[\w]+`
		}
		re, _ := regexp.Compile(searchVariable)
		variable := strings.TrimPrefix(strings.Trim(fmt.
			Sprint(re.FindAllString(currentParagraph, -1)), "[]"), trimVariable[i])
		userVariable = append(userVariable, variable)
		if i == 2 {
			for i := range department {
				if department[i] == variable {
					continue breakDown
				}
			}
			department = append(department, variable)
		}
	}
}

func randSeq(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func remakeBackup() {
	for i := range department {
		fmt.Println(department[i])
	}
	for i := 0; i < 2; i++ { //range users {
		for range users[i] {
			//fmt.Println(m)
			//fmt.Println(users[i][m])
		}
	}
}

func remakeDepartment() {
	for i := range department {
		fmt.Println(department[i])
		if department[i] != "" {
			rand.Seed(time.Now().UnixNano())
			gid := 2500 + len(users) + i
			entryUUID := fmt.Sprintln(randSeq(8) + "-" + randSeq(4) + "-" + randSeq(4) + "-" + randSeq(12))
			for u := range users {
				if department[i] == users[u][2] {
					fmt.Println(users[u][0])
				}
			}
		}
	}
}

func checkError(err error) {
	if err != nil {
		panic(err)
	}
}