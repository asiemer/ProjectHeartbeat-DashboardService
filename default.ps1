properties{
	$projectName = "Iteration0"
    $config = if($useConfig){$useConfig} else {"Debug"};
	$baseDir = Resolve-Path .\
	$srcDir = "$baseDir\src"
    $buildDir = "$baseDir\build\"
	$packagesDir = "$buildDir\$config\"
	$slnFile = "$baseDir\src\Projects.sln"
	
	$testDir = "$buildDir\test"
	$testCopyIgnorePath = "_ReSharper"
	$nunitPath = "$srcDir\packages\NUnit.Runners.2.6.4\tools"
	$unitTestAssembly = "UnitTests.dll"
	$integrationTestAssembly = "IntegrationTests.dll"
}

task default -depends Test 

task Clean {
	msbuild $slnFile /m /t:Clean /p:VisualStudioVersion=12.0
	pushd src
	dir -directory bin -recurse | remove-item -recurse
	dir -directory obj -recurse | remove-item -recurse
	popd
	remove-item $packagesDir -recurse -ErrorAction Ignore
}

task CommonAssemblyInfo -description "Builds common assembly info file" {
	$buildNbr = if($env:build_number){$env:build_number} else {"999"};
	$version = "0.0.0.$buildNbr"   
    create-commonAssemblyInfo "$version" $projectName "$srcDir\CommonAssemblyInfo.cs"
}

task Build -depends Clean,CommonAssemblyInfo -description "Builds solution"{
	msbuild $slnFile /m /p:Configuration=$config /t:Build /p:RunOctoPack=true /p:OctoPackPublishPackageToFileShare=$packagesDir /p:VisualStudioVersion=12.0
}

task Test -depends Build -description "Run all tests" -action {
	copy_all_assemblies_for_test $testDir
	exec {
		& $nunitPath\nunit-console.exe $testDir\$unitTestAssembly $testDir\$integrationTestAssembly /nologo /nodots /xml=$buildDir\TestResult.xml    
	}
}
	
function global:create-commonAssemblyInfo($version,$applicationName,$filename)
{
"using System.Reflection;
using System.Runtime.InteropServices;

//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:2.0.50727.4927
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

[assembly: ComVisibleAttribute(false)]
[assembly: AssemblyVersionAttribute(""$version"")]
[assembly: AssemblyFileVersionAttribute(""$version"")]
[assembly: AssemblyCopyrightAttribute(""Copyright 2013-2015"")]
[assembly: AssemblyProductAttribute(""$applicationName"")]
[assembly: AssemblyCompanyAttribute(""ClearMeasure"")]
[assembly: AssemblyConfigurationAttribute(""release"")]
[assembly: AssemblyInformationalVersionAttribute(""$version"")]"  | out-file $filename -encoding "ASCII"    
}

function global:Copy_and_flatten ($source,$filter,$dest) {
  ls $source -filter $filter  -r | Where-Object{!$_.FullName.Contains("$testCopyIgnorePath") -and !$_.FullName.Contains("packages") }| cp -dest $dest -force
}

function global:copy_all_assemblies_for_test($destination){
  create_directory $destination
  Copy_and_flatten $srcDir *.exe $destination
  Copy_and_flatten $srcDir *.dll $destination
  Copy_and_flatten $srcDir *.config $destination
  Copy_and_flatten $srcDir *.xml $destination
  Copy_and_flatten $srcDir *.pdb $destination
  Copy_and_flatten $srcDir *.sql $destination
  Copy_and_flatten $srcDir *.xlsx $destination
}

function global:create_directory($directory_name)
{
  mkdir $directory_name  -ErrorAction SilentlyContinue  | out-null
}