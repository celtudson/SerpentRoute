let project = new Project("SerpentRoute");
project.addAssets("res/**", {
	nameBaseDir: "res",
	destination: "{dir}/{name}",
	name: "{dir}/{name}"
});
project.addParameter(`--resource ${__dirname}/inlineres/thin_pixel_7.ttf@systemfont`);

//project.addShaders("src/shaders/**");
project.addSources("src");
//project.addDefine("kha_html5_disable_automatic_size_adjust");
//project.targetOptions.html5.disableContextMenu = true;
project.addDefine('kha_html5_disable_automatic_size_adjust');
project.addDefine("kha_no_ogg");
project.addDefine("analyzer-optimize");
project.addParameter("-dce full");
resolve(project);
