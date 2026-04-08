package com.z.container.demo.controller;

import org.springframework.web.bind.annotation.*;
//test
@RestController
@RequestMapping("/api")
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "Hello Docker!";
    }
}