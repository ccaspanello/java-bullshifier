package generator;

public class GradleSettingsGenerator {
	private static write(outputDirectory, projectName, subProjects) {
		def gradleProjectName = (projectName != "" ? projectName : "tester")

		def settingsGradleFile = new File("$outputDirectory/settings.gradle")

		def subProjectsIncludes = subProjects.collect({ "include '$it'" }).join("\n")

		settingsGradleFile.write(""" // Generated by GradleSettingsGenerator
rootProject.name=\"$gradleProjectName\"

$subProjectsIncludes
""")
	}
}
