@{
    # Exclude test files from analysis (they use ConvertTo-SecureString for mock credentials)
    ExcludeRules = @()
    
    # Include all rules by default
    IncludeRules = @('*')
    
    # Configure rule-specific settings
    Rules = @{
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }
        PSAvoidOverwritingBuiltInCmdlets = @{
            Enable = $true
        }
    }
    
    # Severity levels to include
    Severity = @('Error', 'Warning', 'Information')
}
