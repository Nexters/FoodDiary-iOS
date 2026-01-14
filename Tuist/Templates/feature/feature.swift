import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "Feature module template",
    attributes: [
        nameAttribute
    ],
    items: [
        .file(
            path: "FoodDiary/Feature/\(nameAttribute)/Project.swift",
            templatePath: "Project.swift.stencil"
        ),
        .file(
            path: "FoodDiary/Feature/\(nameAttribute)/Sources/ViewModel/\(nameAttribute)ViewModel.swift",
            templatePath: "ViewModel.swift.stencil"
        ),
        .file(
            path: "FoodDiary/Feature/\(nameAttribute)/Sources/ViewController/\(nameAttribute)ViewController.swift",
            templatePath: "ViewController.swift.stencil"
        ),
        .file(
            path: "FoodDiary/Feature/\(nameAttribute)/Tests/\(nameAttribute)Tests.swift",
            templatePath: "Test.swift.stencil"
        ),
        .file(
            path: "FoodDiary/Feature/\(nameAttribute)/Resources/.gitkeep",
            templatePath: ".gitkeep.stencil"
        )
    ]
)

