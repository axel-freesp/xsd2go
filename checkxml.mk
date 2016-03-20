# Makefile to check test XML files against XML-schema (xsd)

# The information is read from an XML file with name $(XSD_FILES:%=%-test)
# which is later used to create the Go testcases. Running this makefile
# is kind of reference test / acceptance test of testcases against a real
# schema validating XML parser.

# Define symbols and include/call this makefile:
# XSD_FILES - all XML schema files to be processed
########################################################################

include Makefile-XSLT

STY_DIR := .

define testcaserule
$(1)-to-pass := $$(shell $(XSLT) $(X_IN) $(2) $(X_STY) $(STY_DIR)/testcases2pass.xsl)
$(1)-to-fail := $$(shell $(XSLT) $(X_IN) $(2) $(X_STY) $(STY_DIR)/testcases2fail.xsl)
#$$(info $(1)-to-pass = $$($(1)-to-pass))
#$$(info $(1)-to-fail = $$($(1)-to-fail))
check: $$($(1)-to-pass:%=%-check) $$($(1)-to-fail:%=%-check)
endef
$(foreach X, $(XSD_FILES), $(eval $(call testcaserule,$X,$(X:%.xsd=%-test.xml))))

define passrule
$(1)-check:
	@error=$$$$($(XSLT) $(X_VAL) $(X_IN) $(2)$(1) $(X_STY) $(STY_DIR)/empty.xsl 2>&1); \
	test -z "$$$$error" || { \
		echo "Error in test file $$(@:%-check=%): $$$$error"; \
	}
endef
$(foreach X, $(XSD_FILES), $(foreach F, $($(X:%=%-to-pass)), $(eval $(call passrule,$F,$(dir $X)))))

define failrule
$(1)-check:
	@error=$$$$($(XSLT) $(X_VAL) $(X_IN) $(2)$(1) $(X_STY) $(STY_DIR)/empty.xsl 2>&1); \
	test -n "$$$$error" || { \
		echo "Error in test file $$(@:%-check=%): should not match to stylesheet"; \
	}
endef
$(foreach X, $(XSD_FILES), $(foreach F, $($(X:%=%-to-fail)), $(eval $(call failrule,$F,$(dir $X)))))

