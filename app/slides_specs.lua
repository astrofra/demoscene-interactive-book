slide_res_x, slide_res_y = 4000, 2250 -- in pixels
slide_width = 10.0 -- in meters
slide_height = (slide_width * slide_res_y) / slide_res_x -- in meters
max_slides = 7
bg_color = hg.Color(78/255.0, 81/255.0, 86/255.0, 1.0)

slide_type = {
    vps = 5,
    car = 6,
    hud = 10
}

action_type = {
    none = 1,
    node = 2,
    func = 3,
    nvid = 4,
    svid = 5 -- home cinema room
}