BeforeAll {
    # Import the function
    . $PSScriptRoot/../../Private/Resolve-ProviderFromUri.ps1
}

Describe 'Resolve-ProviderFromUri' {
    Context 'GitHub Provider Detection' {
        It 'Should detect GitHub from nuget.pkg.github.com host' {
            $uri = [uri]'https://nuget.pkg.github.com/myorg/index.json'
            $result = Resolve-ProviderFromUri -RegistryUri $uri
            $result | Should -Be 'GitHub'
        }
        
        It 'Should detect GitHub with subdomain' {
            $uri = [uri]'https://nuget.pkg.github.com/company/repo/index.json'
            $result = Resolve-ProviderFromUri -RegistryUri $uri
            $result | Should -Be 'GitHub'
        }
    }
    
    Context 'GitLab Provider Detection' {
        It 'Should detect GitLab from /packages/nuget/ path' {
            $uri = [uri]'https://gitlab.com/api/v4/projects/123/packages/nuget/index.json'
            $result = Resolve-ProviderFromUri -RegistryUri $uri
            $result | Should -Be 'GitLab'
        }
        
        It 'Should detect GitLab with self-hosted instance' {
            $uri = [uri]'https://gitlab.mycompany.com/api/v4/projects/456/packages/nuget/index.json'
            $result = Resolve-ProviderFromUri -RegistryUri $uri
            $result | Should -Be 'GitLab'
        }
    }
    
    Context 'Unknown Provider' {
        It 'Should throw for unknown provider' {
            $uri = [uri]'https://unknown.registry.com/index.json'
            { Resolve-ProviderFromUri -RegistryUri $uri } | Should -Throw -ExpectedMessage '*Unable to determine provider*'
        }
    }
}
