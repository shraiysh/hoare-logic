include_directories(/home/shraiysh/Downloads/z3-4.8.6-x64-ubuntu-16.04/include)

add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/lex.yy.cpp
	COMMAND lex -o ${PROJECT_SOURCE_DIR}/lex.yy.cpp ${PROJECT_SOURCE_DIR}/lexer.l
	)

add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/y.tab.cpp
	COMMAND yacc -o ${PROJECT_SOURCE_DIR}/y.tab.cpp -d ${PROJECT_SOURCE_DIR}/parser.y
	)

add_executable(main interpreter.cpp lex.yy.cpp y.tab.cpp)
