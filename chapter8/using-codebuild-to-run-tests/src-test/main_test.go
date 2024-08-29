package main

import (
	"testing"
)

// TestSayHello tests the sayHello function
func TestSayHello(t *testing.T) {
	testCases := []*struct {
		Name           string
		Input          string
		ExpectedResult string
	}{
		{
			Name:           "Empty string is passed",
			Input:          "",
			ExpectedResult: "Hello World!",
		},
		{
			Name:           "Single lowercase name",
			Input:          "foo",
			ExpectedResult: "Hello Foo!",
		},
		{
			Name:           "Multiple lowecase name",
			Input:          "foo bar",
			ExpectedResult: "Hello Foo Bar!",
		},
		{
			Name:           "Single mixed case name",
			Input:          "fOo",
			ExpectedResult: "Hello Foo!",
		},
		{
			Name:           "Multiple mixed case name",
			Input:          "FoO baR",
			ExpectedResult: "Hello Foo Bar!",
		},
	}

	for _, testCase := range testCases {
		t.Run(testCase.Name, func(subT *testing.T) {
			actualResult := sayHello(testCase.Input)

			if actualResult == testCase.ExpectedResult {
				return
			}

			subT.Fatalf("expected %q. got %q", testCase.ExpectedResult, actualResult)
		})
	}
}
