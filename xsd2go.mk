# Makefile to create a Go module from XML-schema (xsd)

# Define symbols and include/call this makefile:
# XSD_FILES - all XML schema files to be processed
# TARGET_DIR - target folder (common for all XSD_FILES)
# PACKAGE_NAME (common for all XSD_FILES)
########################################################################

include Makefile-XSLT

PWD := $(shell pwd)
SRC_NODIR := $(notdir $(XSD_FILES))
TARGETS := $(SRC_NODIR:%.xsd=$(TARGET_DIR)/%.go) $(SRC_NODIR:%.xsd=$(TARGET_DIR)/%_test.go) $(SRC_NODIR:%.xsd=$(TARGET_DIR)/test/%_main.go)

STY_DIR := .
STY := $(wildcard $(STY_DIR)/*.xsl)

ifneq ($(PACKAGE_NAME),)
APPLY_PARAM := $(X_PARM) package-name "'$(PACKAGE_NAME)'"
PACKAGE_PATH := $(subst $(GOPATH)/src/,,$(PWD))/$(TARGET_DIR)
$(info PACKAGE_PATH = $(PACKAGE_PATH))
endif

.PHONY: all test clean
all: $(TARGETS)

# assume targets are up to date
# TODO: execute to copy the XML testcases and compare results
# challenge:
# - main program must be package main
# - how to import the built package (parse PWD and GOPATH?)
test:
	go build -o $(TARGET_DIR)/main ./$(TARGET_DIR)/test
	go test ./$(TARGET_DIR)
	( cd ./$(TARGET_DIR) && ./main )

clean:
	rm -Rf $(TARGET_DIR)

define targetrule
$(1): $(2) $(STY) | $(TARGET_DIR)
	$(XSLT) $(X_VAL) $(APPLY_PARAM) $(X_IN) $$< $(X_STY) $(STY_DIR)/xsd2go.xsl | $(X_TO_C) > $$@
endef
$(foreach X, $(XSD_FILES), $(eval $(call targetrule,$(TARGET_DIR)/$(notdir $(X:%.xsd=%.go)),$X)))

define testtargetrule
TEST_PARAM := $(X_PARM) testcases-filename "'$(3)'" $(X_PARM) testfiles-prefix "'$(PWD)/$$(dir $(2))'"
$(1): $(2) $(3) $(STY) | $(TARGET_DIR)
	$(XSLT) $(X_VAL) $(APPLY_PARAM) $$(TEST_PARAM) $(X_IN) $$< $(X_STY) $(STY_DIR)/xsd2gotest.xsl | $(X_TO_C) > $$@
endef
$(foreach X, $(XSD_FILES), $(eval $(call testtargetrule,$(TARGET_DIR)/$(notdir $(X:%.xsd=%_test.go)),$X,$(X:%.xsd=%-test.xml))))

define copytargetrule
TEST_PARAM := $(X_PARM) testcases-filename "'$(3)'" $(X_PARM) testfiles-prefix "'$(PWD)/$$(dir $(2))'"
$(1): $(2) $(3) $(STY) | $(TARGET_DIR)/test
	$(XSLT) $(X_VAL) $(X_PARM) package "'$(PACKAGE_PATH)'" $$(TEST_PARAM) $(X_IN) $$< $(X_STY) $(STY_DIR)/xsd2gomain.xsl | $(X_TO_C) > $$@
endef
$(foreach X, $(XSD_FILES), $(eval $(call copytargetrule,$(TARGET_DIR)/test/$(notdir $(X:%.xsd=%_main.go)),$X,$(X:%.xsd=%-test.xml))))

$(TARGET_DIR) $(TARGET_DIR)/test:
	mkdir -p $@
