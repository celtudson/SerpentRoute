class Achievement {
	public final root:Achievements;
	public final title:String;
	public final description:String;

	public function new(_root:Achievements, _title:String, _description:String) {
		if (_root == null) throw "Achievement.new: _root is null";
		root = _root;
		title = _title;
		description = _description;
		root.listOfAll.push(this);
	}

	public function achieve():Bool {
		return root.achieve(this);
	}
}

class Achievements {
	public final listOfAll:Array<Achievement> = [];
	public final achievedIds:Array<Int> = [];

	public function new() {}

	public function add(_title:String, _description:String):Achievement {
		final achievement = new Achievement(this, _title, _description);
		return achievement;
	}

	public function achieve(_achievement:Achievement):Bool {
		final id = listOfAll.indexOf(_achievement);
		if (listOfAll.contains(_achievement) && !achievedIds.contains(id)) {
			achievedIds.push(id);
			return true;
		}
		return false;
	}

	// public function getBytes():Int {}
}
