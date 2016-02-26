#

EXAMPLES := $(filter-out examples/xml.xsd, $(wildcard examples/*.xsd))
.PHONY: test all clean check
test: $(EXAMPLES:%=%-test)
all: $(EXAMPLES:%=%-all)
clean: $(EXAMPLES:%=%-clean)
check: $(EXAMPLES:%=%-check)
########################################################################

define gocreate-rule
$(1)_PARAMS := XSD_FILES=$(2) TARGET_DIR=test/$(1) PACKAGE_NAME=$$(subst -,_,$(1))
$$(info PACKAGE_NAME=$$(subst -,_,$(1)))
.PHONY: $(2)-test
$(2)-test: $(2)-all
	@make -s -f xsd2go.mk $$($(1)_PARAMS) test
.PHONY: $(2)-all
$(2)-all:
	@make -s -f xsd2go.mk $$($(1)_PARAMS) all
.PHONY: $(2)-clean
$(2)-clean:
	@make -s -f xsd2go.mk $$($(1)_PARAMS) clean
.PHONY: $(2)-check
$(2)-check:
	@make -s -f checkxml.mk XSD_FILES=$(2) check
endef
$(foreach E, $(EXAMPLES), $(eval $(call gocreate-rule,$(E:examples/%.xsd=%),$E)))


